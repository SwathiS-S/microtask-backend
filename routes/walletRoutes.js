const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Notification = require('../models/Notification');

// GET /wallet/balance/:userId - Get wallet balance
router.get('/balance/:userId', async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ userId: req.params.userId });
    if (!wallet) {
      // Create wallet if it doesn't exist (e.g. for new users)
      const user = await User.findById(req.params.userId);
      if (!user) return res.status(404).json({ success: false, message: 'User not found' });
      
      wallet = new Wallet({ 
        userId: user._id, 
        role: user.role === 'taskProvider' ? 'provider' : 'user', 
        balance: 0,
        pendingWithdrawal: 0
      });
      await wallet.save();
    }
    res.json({ success: true, balance: wallet.balance, pendingWithdrawal: wallet.pendingWithdrawal });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /wallet/transactions/:userId - Get all transactions
router.get('/transactions/:userId', async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ userId: req.params.userId });
    if (!wallet) {
      const user = await User.findById(req.params.userId);
      if (!user) return res.status(404).json({ success: false, message: 'User not found' });
      
      wallet = new Wallet({ 
        userId: user._id, 
        role: user.role === 'taskProvider' ? 'provider' : 'user', 
        balance: 0 
      });
      await wallet.save();
    }
    res.json({ success: true, transactions: (wallet.transactions || []).sort((a,b) => b.date - a.date) });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /wallet/withdraw - User requests withdrawal
router.post('/withdraw', async (req, res) => {
  try {
    const { userId, amount, bankDetails } = req.body;

    const mongoose = require('mongoose');
    // Step 2: Check wallet balance
    const wallet = await Wallet.findOne({ userId: mongoose.Types.ObjectId(userId) });
    if (!wallet) {
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }

    // Step 1: Check dynamic minimum amount and sufficient balance
    const walletBalance = wallet.balance;
    const minimumWithdrawal = walletBalance < 100 ? 1 : 10;
    const requestedAmount = parseFloat(amount);

    if (requestedAmount < minimumWithdrawal) {
      return res.status(400).json({
        success: false,
        message: `Minimum withdrawal amount is ₹${minimumWithdrawal}`
      });
    }

    if (requestedAmount > walletBalance) {
      return res.status(400).json({
        success: false,
        message: `Insufficient balance. Your balance: ₹${walletBalance} Requested: ₹${requestedAmount}`
      });
    }

    // Step 3: Deduct from wallet and update pending withdrawal balance
    await Wallet.findOneAndUpdate(
      { userId },
      {
        $inc: {
          balance: -amount,
          pendingWithdrawal: +amount
        },
        $push: {
          transactions: {
            type: 'withdrawal',
            amount: amount,
            description: 'Withdrawal requested',
            status: 'pending',
            date: new Date()
          }
        }
      }
    );

    // Step 4: Create withdrawal request
    const user = await User.findById(userId);
    const withdrawal = await Withdrawal.create({
      userId,
      userName: user ? user.name : 'N/A',
      amount,
      bankDetails,
      status: 'pending',
      requestedAt: new Date()
    });

    // Step 5: Create notification for user
    await Notification.create({
      recipient: userId,
      title: '⏳ Withdrawal Requested',
      message: `Your withdrawal request of ₹${amount} has been submitted. Expected processing time is 1-2 business days.`,
      type: 'WITHDRAWAL_REQUESTED'
    });

    res.json({
      success: true,
      message: 'Withdrawal requested successfully',
      withdrawalId: withdrawal._id,
      expectedTime: '1-2 business days'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// GET /wallet/withdrawal-history/:userId - Get withdrawal history
router.get('/withdrawal-history/:userId', async (req, res) => {
  try {
    const history = await Withdrawal.find({ userId: req.params.userId }).sort({ requestedAt: -1 }).populate('bankAccountId');
    res.json({ success: true, history });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
