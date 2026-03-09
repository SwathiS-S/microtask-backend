const express = require('express');
const router = express.Router();
const BankAccount = require('../models/BankAccount');

// POST /bank/add - Add bank account
router.post('/add', async (req, res) => {
  try {
    const { userId, role, accountHolderName, accountNumber, ifscCode, bankName, branchName, accountType } = req.body;
    
    // Check if account already exists
    const existing = await BankAccount.findOne({ userId });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Bank account already exists for this user' });
    }

    const bankAccount = new BankAccount({
      userId,
      role,
      accountHolderName,
      accountNumber, // In real app, encrypt before saving
      ifscCode,
      bankName,
      branchName,
      accountType,
      isVerified: true, // For demo purposes, auto-verify
    });

    await bankAccount.save();
    res.json({ success: true, message: 'Bank account added successfully', bankAccount });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /bank/details/:userId - Get bank details
router.get('/details/:userId', async (req, res) => {
  try {
    const bankAccount = await BankAccount.findOne({ userId: req.params.userId });
    if (!bankAccount) {
      return res.status(404).json({ success: false, message: 'Bank account not found' });
    }
    res.json({ success: true, bankAccount });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// PUT /bank/update/:userId - Update bank details
router.put('/update/:userId', async (req, res) => {
  try {
    const bankAccount = await BankAccount.findOneAndUpdate(
      { userId: req.params.userId },
      req.body,
      { new: true }
    );
    if (!bankAccount) {
      return res.status(404).json({ success: false, message: 'Bank account not found' });
    }
    res.json({ success: true, message: 'Bank account updated successfully', bankAccount });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// DELETE /bank/remove/:userId - Remove bank account
router.delete('/remove/:userId', async (req, res) => {
  try {
    const bankAccount = await BankAccount.findOneAndDelete({ userId: req.params.userId });
    if (!bankAccount) {
      return res.status(404).json({ success: false, message: 'Bank account not found' });
    }
    res.json({ success: true, message: 'Bank account removed successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /bank/verify/:userId - Verify bank account
router.post('/verify/:userId', async (req, res) => {
  try {
    const bankAccount = await BankAccount.findOneAndUpdate(
      { userId: req.params.userId },
      { isVerified: true },
      { new: true }
    );
    if (!bankAccount) {
      return res.status(404).json({ success: false, message: 'Bank account not found' });
    }
    res.json({ success: true, message: 'Bank account verified successfully', bankAccount });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
