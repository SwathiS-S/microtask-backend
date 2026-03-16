const express = require('express');
const router = express.Router();
const User = require('../models/User'); 
const Notification = require('../models/Notification'); 
const Wallet = require('../models/Wallet');           // ← ADD THIS 
const Withdrawal = require('../models/Withdrawal');   // ← ADD THIS 

// GET /wallet/balance/:userId - Get wallet balance
router.get('/balance/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    console.log('Fetching wallet for:', userId);

    const wallet = await Wallet.findOne({
      userId: userId
    });

    console.log('Wallet found:', wallet);

    res.json({
      success: true,
      balance: wallet?.balance || 0,
      escrowBalance: wallet?.escrowBalance || 0,  // ← ADD THIS 
      pendingWithdrawal: wallet?.pendingWithdrawal || 0,
      transactions: (wallet?.transactions || []).map(tx => ({
        ...tx.toObject(),
        type: tx.transactionType // for backward compatibility
      }))
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
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
    res.json({ 
      success: true, 
      transactions: (wallet.transactions || [])
        .sort((a,b) => b.date - a.date)
        .map(tx => {
          const txObj = tx.toObject ? tx.toObject() : tx;
          return {
            ...txObj,
            type: txObj.transactionType,
            transactionType: txObj.transactionType
          };
        })
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /wallet/withdraw - User requests withdrawal
router.post('/withdraw', async (req, res) => {
  try {
    console.log('=== WITHDRAWAL START ===');
    console.log('Body:', req.body);

    const { userId, amount, bankDetails } = req.body;

    // Find wallet
    const wallet = await Wallet.findOne({
      userId: userId
    });

    console.log('Wallet:', wallet);
    console.log('Balance:', wallet?.balance);
    console.log('Requested:', amount);

    if (!wallet) {
      return res.status(400).json({
        success: false,
        message: 'Wallet not found'
      });
    }

    if (Number(wallet.balance) < Number(amount)) {
      return res.status(400).json({
        success: false,
        message: `Insufficient balance.
        Available: ₹${wallet.balance}`
      });
    }

    // Deduct balance
    const updated = await Wallet.findOneAndUpdate(
      { userId: userId },
      {
        $inc: {
          balance: -Number(amount),
          pendingWithdrawal: +Number(amount)
        },
        $push: {
          transactions: {
            transactionType: 'withdrawal',
            amount: Number(amount),
            description: 'Withdrawal requested',
            status: 'pending',
            date: new Date()
          }
        }
      },
      { new: true }
    );

    console.log('Updated balance:', updated.balance);

    // Fetch user name before creating withdrawal 
    const user = await User.findById(userId); 
    if (!user) return res.status(404).json({ success: false, message: 'User not found' }); 

    // Create withdrawal record
    const withdrawal = await Withdrawal.create({
      userId: userId,
      userName: user.name || user.fullName || user.email, // ← ADD THIS 
      amount: Number(amount),
      bankDetails: bankDetails,
      status: 'pending',
      requestedAt: new Date()
    });

    console.log('Withdrawal created:', withdrawal._id);
    console.log('=== WITHDRAWAL DONE ===');

    return res.json({
      success: true,
      message: 'Withdrawal requested successfully!',
      withdrawalId: withdrawal._id
    });

  } catch (error) {
    console.log('WITHDRAWAL ERROR:', error.message);
    console.log('Full error:', error);
    return res.status(500).json({
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
