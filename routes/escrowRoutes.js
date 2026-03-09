const express = require('express');
const router = express.Router();
const Escrow = require('../models/Escrow');
const Wallet = require('../models/Wallet');
const Task = require('../models/Task');
const Notification = require('../models/Notification');

// POST /escrow/deposit/:taskId - Provider deposits escrow
router.post('/deposit/:taskId', async (req, res) => {
  try {
    const { providerId, amount } = req.body;
    
    // Check provider wallet balance
    const wallet = await Wallet.findOne({ userId: providerId });
    if (!wallet || wallet.balance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient balance' });
    }

    // Deduct from wallet and add to escrowBalance
    wallet.balance -= amount;
    wallet.escrowBalance += amount;
    wallet.transactions.push({
      type: 'escrow_hold',
      amount,
      taskId: req.params.taskId,
      description: 'Funds held in escrow for task',
      status: 'completed'
    });
    await wallet.save();

    // Create escrow record
    const escrow = new Escrow({
      taskId: req.params.taskId,
      providerId,
      amount,
      status: 'held'
    });
    await escrow.save();

    // Update task status to "funded"
    await Task.findByIdAndUpdate(req.params.taskId, { status: 'funded' });

    res.json({ success: true, message: 'Funds deposited to escrow', escrow });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /escrow/release/:taskId - Release to user
router.post('/release/:taskId', async (req, res) => {
  try {
    const { userId } = req.body; // Worker's user ID
    
    const escrow = await Escrow.findOne({ taskId: req.params.taskId, status: 'held' });
    if (!escrow) {
      return res.status(404).json({ success: false, message: 'Held escrow record not found' });
    }

    // Update escrow record
    escrow.status = 'released';
    escrow.userId = userId;
    escrow.releasedAt = Date.now();
    await escrow.save();

    // Release from provider escrow balance
    const providerWallet = await Wallet.findOne({ userId: escrow.providerId });
    const task = await Task.findById(req.params.taskId);
    if (providerWallet) {
      providerWallet.escrowBalance -= escrow.amount;
      providerWallet.transactions.push({
        type: 'escrow_release',
        amount: escrow.amount,
        taskId: req.params.taskId,
        taskTitle: task ? task.title : 'Task',
        description: `Payment Released - ₹${escrow.amount}`,
        status: 'completed'
      });
      await providerWallet.save();
    }

    // Credit to worker's wallet balance
    const workerWallet = await Wallet.findOne({ userId });
    const txDescription = `+ ₹${escrow.amount} received for ${task ? task.title : 'Task'}`;
    if (!workerWallet) {
      // Create wallet if it doesn't exist
      const newWallet = new Wallet({
        userId,
        role: 'user',
        balance: escrow.amount,
        transactions: [{
          type: 'credit',
          amount: escrow.amount,
          taskId: req.params.taskId,
          taskTitle: task ? task.title : 'Task',
          description: txDescription,
          status: 'completed'
        }]
      });
      await newWallet.save();
    } else {
      workerWallet.balance += escrow.amount;
      workerWallet.transactions.push({
        type: 'credit',
        amount: escrow.amount,
        taskId: req.params.taskId,
        taskTitle: task ? task.title : 'Task',
        description: txDescription,
        status: 'completed'
      });
      await workerWallet.save();
    }

    // Update task status to "completed"
    if (task) {
      task.status = 'completed';
      await task.save();

      // Notify User
      await Notification.create({
        recipient: userId,
        sender: escrow.providerId,
        title: 'Payment Received! 💰',
        message: `Your work for "${task.title}" has been approved and ₹${escrow.amount} has been added to your wallet.`,
        type: 'PAYMENT_RELEASED',
        taskId: task._id
      });
    }

    res.json({ success: true, message: 'Funds released from escrow to worker' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /escrow/refund/:taskId - Refund to provider
router.post('/refund/:taskId', async (req, res) => {
  try {
    const escrow = await Escrow.findOne({ taskId: req.params.taskId, status: 'held' });
    if (!escrow) {
      return res.status(404).json({ success: false, message: 'Held escrow record not found' });
    }

    // Update escrow record
    escrow.status = 'refunded';
    escrow.refundedAt = Date.now();
    await escrow.save();

    // Release from provider escrow balance back to wallet balance
    const providerWallet = await Wallet.findOne({ userId: escrow.providerId });
    if (providerWallet) {
      providerWallet.escrowBalance -= escrow.amount;
      providerWallet.balance += escrow.amount;
      providerWallet.transactions.push({
        type: 'refund',
        amount: escrow.amount,
        taskId: req.params.taskId,
        description: 'Escrow refunded to wallet',
        status: 'completed'
      });
      await providerWallet.save();
    }

    // Update task status to "expired" or "cancelled"
    await Task.findByIdAndUpdate(req.params.taskId, { status: 'expired' });

    res.json({ success: true, message: 'Funds refunded from escrow to provider' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /escrow/dispute/:taskId - Raise dispute
router.post('/dispute/:taskId', async (req, res) => {
  try {
    const { reason } = req.body;
    const escrow = await Escrow.findOneAndUpdate(
      { taskId: req.params.taskId, status: 'held' },
      { status: 'disputed', reason },
      { new: true }
    );
    if (!escrow) {
      return res.status(404).json({ success: false, message: 'Held escrow record not found' });
    }
    
    // Update task status to "disputed"
    await Task.findByIdAndUpdate(req.params.taskId, { status: 'disputed' });

    res.json({ success: true, message: 'Dispute raised successfully', escrow });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /escrow/status/:taskId - Check escrow status
router.get('/status/:taskId', async (req, res) => {
  try {
    const escrow = await Escrow.findOne({ taskId: req.params.taskId });
    if (!escrow) {
      return res.status(404).json({ success: false, message: 'Escrow record not found' });
    }
    res.json({ success: true, escrow });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
