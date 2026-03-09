const express = require('express');
const router = express.Router();
const Wallet = require('../models/Wallet');
const Withdrawal = require('../models/Withdrawal');
const BankAccount = require('../models/BankAccount');

// GET /wallet/balance/:userId - Get wallet balance
router.get('/balance/:userId', async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ userId: req.params.userId });
    if (!wallet) {
      return res.status(404).json({ success: false, message: 'Wallet not found' });
    }
    res.json({ success: true, balance: wallet.balance, escrowBalance: wallet.escrowBalance });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /wallet/transactions/:userId - Get all transactions
router.get('/transactions/:userId', async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ userId: req.params.userId });
    if (!wallet) {
      return res.status(404).json({ success: false, message: 'Wallet not found' });
    }
    res.json({ success: true, transactions: wallet.transactions.sort((a,b) => b.date - a.date) });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /wallet/withdraw - Request withdrawal
router.post('/withdraw', async (req, res) => {
  try {
    const { userId, amount, bankAccountId } = req.body;
    
    // Check wallet balance
    const wallet = await Wallet.findOne({ userId });
    if (!wallet || wallet.balance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient balance' });
    }

    // Deduct from wallet
    wallet.balance -= amount;
    wallet.transactions.push({
      type: 'withdrawal',
      amount,
      description: 'Withdrawal requested to bank account',
      status: 'pending'
    });
    await wallet.save();

    // Create withdrawal request
    const withdrawal = new Withdrawal({
      userId,
      amount,
      bankAccountId,
      status: 'pending'
    });
    await withdrawal.save();

    res.json({ success: true, message: 'Withdrawal request submitted', withdrawal });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
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
