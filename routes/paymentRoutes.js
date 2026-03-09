const express = require('express');
const crypto = require('crypto');
const router = express.Router();
const User = require('../models/User');
const Task = require('../models/Task');
const Transaction = require('../models/Transaction');
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
      admin.wallet = (admin.wallet || 0) + adminCommission;
      await admin.save();
      
      await Transaction.create({
        user_id: admin._id,
        task_id: task._id,
        amount: adminCommission,
        type: 'COMMISSION',
        status: 'SUCCESS'
      });
    }

    // Update User Wallet
    worker.wallet = (worker.wallet || 0) + userEarnings;
    await worker.save();

    await Transaction.create({
      user_id: worker._id,
      task_id: task._id,
      amount: userEarnings,
      type: 'CREDIT',
      status: 'SUCCESS'
    });

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
    const key_secret = process.env.RAZORPAY_KEY_SECRET;
    if (!key_secret) return res.status(500).json({ success: false, message: 'Razorpay not configured' });
    const expected = crypto.createHmac('sha256', key_secret).update(razorpay_order_id + '|' + razorpay_payment_id).digest('hex');
    if (expected !== razorpay_signature) {
      return res.status(400).json({ success: false, message: 'Signature verification failed' });
    }
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    const addAmount = Number(amount);
    if (!addAmount || addAmount <= 0) return res.status(400).json({ success: false, message: 'Invalid amount' });
    user.wallet = (Number(user.wallet) || 0) + addAmount;
    await user.save();
    try {
      await Transaction.create({
        user_id: user._id,
        amount: addAmount,
        type: 'CREDIT',
        status: 'SUCCESS'
      });
    } catch (_) {}
    res.json({ success: true, message: 'Payment verified and wallet credited', wallet: Number(user.wallet) });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to verify payment' });
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
