const express = require('express');
const crypto = require('crypto');
const router = express.Router();
const User = require('../models/User');
const Task = require('../models/Task');
const Transaction = require('../models/Transaction');
const Escrow = require('../models/Escrow');
const Wallet = require('../models/Wallet');
const { getClient, verifySignature } = require('../services/razorpay');

router.post('/razorpay/create-order', async (req, res) => {
  try {
    const { amount, userId, currency, receipt, notes } = req.body || {};
    const a = Number(amount);
    if (!userId || !a || a <= 0) return res.status(400).json({ success: false, message: 'Valid userId and amount required' });
    const client = getClient();
    if (!client) return res.status(500).json({ success: false, message: 'Razorpay not configured' });
    const order = await client.orders.create({
      amount: Math.round(a * 100),
      currency: currency || 'INR',
      receipt: receipt || String(Date.now()),
      notes: notes || {}
    });
    res.json({ success: true, order });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to create order' });
  }
});

// Step 3: Verify payment and fund task
router.post('/razorpay/verify-escrow-payment', async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, taskId, providerId, amount } = req.body || {};
    
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature || !taskId || !providerId) {
      return res.status(400).json({ success: false, message: 'Missing fields' });
    }

    const isValid = verifySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature);
    if (!isValid) {
      return res.status(400).json({ success: false, message: 'Signature verification failed' });
    }

    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

    // Update Task Status
    task.status = 'open'; // funded -> open as per Step 3
    await task.save();

    // Create Escrow record
    const escrow = new Escrow({
      taskId,
      providerId,
      amount: amount || task.amount,
      status: 'held',
      heldAt: new Date()
    });
    await escrow.save();

    // Provider wallet transaction
    let wallet = await Wallet.findOne({ userId: providerId });
    if (!wallet) {
      wallet = new Wallet({ userId: providerId, role: 'provider', balance: 0 });
    }
    
    // Log the funding in transactions
    wallet.transactions.push({
      type: 'escrow_hold',
      amount: amount || task.amount,
      taskId: task._id,
      taskTitle: task.title,
      description: `Task Funded - ₹${amount || task.amount} debited`,
      status: 'completed',
      date: new Date()
    });
    await wallet.save();

    res.json({ success: true, message: 'Task funded and published successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Verification failed' });
  }
});

router.post('/razorpay/verify-task-payment', async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, taskId } = req.body || {};
    
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature || !taskId) {
      return res.status(400).json({ success: false, message: 'Missing fields' });
    }

    const isValid = verifySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature);
    if (!isValid) {
      return res.status(400).json({ success: false, message: 'Signature verification failed' });
    }

    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

    const worker = await User.findById(task.acceptedBy);
    if (!worker) return res.status(404).json({ success: false, message: 'Worker not found' });

    // Commission Calculation (20% as per example)
    const adminCommission = Math.round(task.amount * 0.20);
    const userEarnings = task.amount - adminCommission;

    // Find Provider
    const provider = await User.findById(task.postedBy);
    if (provider) {
      await Transaction.create({
        user_id: provider._id,
        task_id: task._id,
        amount: task.amount,
        type: 'DEBIT',
        status: 'SUCCESS'
      });
    }

    // Find Admin
    const admin = await User.findOne({ role: 'admin' });
    if (admin) {
      let adminWallet = await Wallet.findOne({ userId: admin._id });
      if (!adminWallet) adminWallet = new Wallet({ userId: admin._id, role: 'user', balance: 0 });
      adminWallet.balance = (adminWallet.balance || 0) + adminCommission;
      adminWallet.transactions.push({
        type: 'credit',
        amount: adminCommission,
        taskId: task._id,
        taskTitle: task.title,
        description: `Admin Commission for Task: ${task.title}`,
        status: 'completed',
        date: new Date()
      });
      await adminWallet.save();
    }

    // Update User Wallet
    let workerWallet = await Wallet.findOne({ userId: worker._id });
    if (!workerWallet) workerWallet = new Wallet({ userId: worker._id, role: 'user', balance: 0 });
    workerWallet.balance = (workerWallet.balance || 0) + userEarnings;
    workerWallet.transactions.push({
      type: 'credit',
      amount: userEarnings,
      taskId: task._id,
      taskTitle: task.title,
      description: `Payment received for Task: ${task.title}`,
      status: 'completed', 
      date: new Date()
    });
    await workerWallet.save();

    // Update Task Status
    task.status = 'paid';
    await task.save();

    res.json({ 
      success: true, 
      message: 'Payment verified and wallets updated', 
      userEarnings, 
      adminCommission 
    });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to verify payment' });
  }
});

router.post('/razorpay/verify', async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, userId, amount } = req.body || {};
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature || !userId || amount == null) {
      return res.status(400).json({ success: false, message: 'Missing fields' });
    }
    const isValid = verifySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature);
    if (!isValid) {
      return res.status(400).json({ success: false, message: 'Signature verification failed' });
    }
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    const addAmount = Number(amount);
    if (!addAmount || addAmount <= 0) return res.status(400).json({ success: false, message: 'Invalid amount' });
    
    let wallet = await Wallet.findOne({ userId });
    if (!wallet) wallet = new Wallet({ userId, role: user.role === 'taskProvider' ? 'provider' : 'user', balance: 0 });
    wallet.balance = (Number(wallet.balance) || 0) + addAmount;
    wallet.transactions.push({
      type: 'credit',
      amount: addAmount,
      description: 'Added Funds via Razorpay',
      status: 'completed',
      date: new Date()
    });
    await wallet.save();

    res.json({ success: true, message: 'Funds added to wallet', balance: wallet.balance });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Verification failed' });
  }
});

router.post('/razorpay/webhook', async (req, res) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET || 'your_webhook_secret';
  const signature = req.headers['x-razorpay-signature'];
  
  // Verification logic would go here if needed
  console.log('Razorpay Webhook Received:', req.body);
  
  // For now, just return 200
  res.status(200).send('ok');
});

module.exports = router;
