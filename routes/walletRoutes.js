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
    const { userId, amount, bankDetails } = req.body;
    if (!userId || !amount) return res.status(400).json({ success: false, message: 'userId and amount required' });

    const wallet = await Wallet.findOne({ userId });
    if (!wallet) return res.status(404).json({ success: false, message: 'Wallet not found' });
    if (wallet.balance < amount) return res.status(400).json({ success: false, message: 'Insufficient balance' });

    // Deduct balance and add pending withdrawal 
    await Wallet.findOneAndUpdate(
      { userId },
      { 
        $inc: { balance: -Number(amount), pendingWithdrawal: +Number(amount) },
        $push: { 
          transactions: {
            transactionType: 'withdrawal', 
            amount: Number(amount), 
            description: `Withdrawal ₹${amount} requested`, 
            status: 'pending', 
            date: new Date() 
          } 
        } 
      }
    );

    // Create withdrawal record 
    const user = await User.findById(userId);
    await Withdrawal.create({ 
      userId, 
      userName: user?.name || 'Unknown', 
      amount: Number(amount), 
      bankDetails: bankDetails || {}, 
      status: 'pending', 
      requestedAt: new Date() 
    });

    // Update User model wallet for backward compatibility
    await User.findByIdAndUpdate(userId, { $inc: { wallet: -Number(amount) } });

    res.json({ success: true, message: `Withdrawal of ₹${amount} requested successfully!` });
  } catch(e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// GET /wallet/withdrawals/:userId - Get withdrawal history
router.get('/withdrawals/:userId', async (req, res) => { 
  try { 
    const withdrawals = await Withdrawal.find({ userId: req.params.userId }) 
      .sort({ requestedAt: -1 }); 
    res.json({ success: true, withdrawals }); 
  } catch(e) { 
    res.status(500).json({ success: false, message: e.message }); 
  } 
}); 

module.exports = router;
