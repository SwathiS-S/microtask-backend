const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Notification = require('../models/Notification');
const Wallet = require('../models/Wallet'); 
const Withdrawal = require('../models/Withdrawal'); 

router.get('/balance/:userId', async (req, res) => { 
   try { 
     const mongoose = require('mongoose'); 
     let wallet = await Wallet.findOne({ 
       userId: req.params.userId 
     }) || await Wallet.findOne({ 
       userId: new mongoose.Types.ObjectId( 
         req.params.userId 
       ) 
     }); 
 
     if (!wallet) { 
       const user = await User.findById( 
         req.params.userId 
       ); 
       if (!user) { 
         return res.status(404).json({ 
           success: false, 
           message: 'User not found' 
         }); 
       } 
       wallet = await Wallet.create({ 
         userId: user._id, 
         role: user.role === 'taskProvider' 
           ? 'provider' : 'user', 
         balance: 0 
       }); 
     } 
 
     return res.json({ 
       success: true, 
       balance: Number(wallet.balance || 0), 
       escrowBalance: Number(wallet.escrowBalance || 0), 
       pendingWithdrawal: Number( 
         wallet.pendingWithdrawal || 0 
       ), 
       transactions: wallet.transactions || [] 
     }); 
 
   } catch (error) { 
     return res.status(500).json({ 
       success: false, 
       balance: 0, 
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

    // Find wallet - try both ways
    let wallet = await Wallet.findOne({ userId: userId });

    if (!wallet) {
      wallet = await Wallet.findOne({ 
        userId: mongoose.Types.ObjectId(userId) 
      });
    }

    console.log('Wallet found:', wallet);
    console.log('Balance:', wallet?.balance);
    console.log('Requested:', amount);

    if (!wallet || Number(wallet.balance) < Number(amount)) {
      return res.status(400).json({
        success: false,
        message: `Insufficient balance. Available: ₹${wallet?.balance || 0}`
      });
    }

    // Deduct from wallet
    await Wallet.findOneAndUpdate(
      { userId: userId },
      {
        $inc: { 
          balance: -Number(amount), 
          pendingWithdrawal: +Number(amount) 
        },
        $push: {
          transactions: {
            type: 'withdrawal',
            amount: Number(amount),
            description: 'Withdrawal requested',
            status: 'pending',
            date: new Date()
          }
        }
      }
    );

    // Create withdrawal record
    const user = await User.findById(userId);
    await Withdrawal.create({
      userId: userId,
      userName: user ? user.name : 'N/A',
      amount: Number(amount),
      bankDetails: bankDetails,
      status: 'pending',
      requestedAt: new Date()
    });

    res.json({
      success: true,
      message: 'Withdrawal requested successfully!'
    });

  } catch (error) {
    console.log('Withdrawal error:', error);
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
