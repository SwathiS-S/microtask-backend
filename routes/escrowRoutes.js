const express = require('express');
const router = express.Router();
const Escrow = require('../models/Escrow');
const Wallet = require('../models/Wallet');
const Task = require('../models/Task');
const Notification = require('../models/Notification');

// Fix 2: Admin dashboard fetch all pending escrows
router.get('/admin/escrow/pending', async (req, res) => { 
   try { 
     console.log('=== PENDING ESCROWS ==='); 
 
     const pendingTasks = await Task.find({ 
       status: 'pending_release' 
     }).populate('postedBy', 'name email') 
       .populate('acceptedBy', 'name email'); 
 
     console.log('Pending tasks:', pendingTasks.length); 
 
     return res.json({ 
       success: true, 
       tasks: pendingTasks 
     }); 
 
   } catch (error) { 
     console.log('Error:', error.message); 
     return res.status(500).json({ 
       success: false, 
       message: error.message 
     }); 
   } 
 }); 


router.post('/admin/escrow/release/:taskId', 
   async (req, res) => { 
   try { 
     const { taskId } = req.params; 
 
     const task = await Task.findById(taskId); 
     const workerId = task.acceptedBy 
       || task.assignedTo; 
     const releaseAmount = task.workerAmount 
       || Math.round(Number(task.amount) * 0.8); 
 
     console.log('Releasing to worker:', workerId); 
     console.log('Amount:', releaseAmount); 
 
     // Credit worker wallet 
     const workerWallet = await Wallet.findOneAndUpdate( 
       { userId: workerId }, 
       { 
         $inc: { balance: Number(releaseAmount) }, 
         $push: { 
           transactions: { 
             type: 'credit', 
             amount: Number(releaseAmount), 
             taskId: taskId, 
             description: 'Payment released from escrow', 
             status: 'completed', 
             date: new Date() 
           } 
         } 
       }, 
       { upsert: true, new: true } 
     ); 
 
     console.log('Worker balance:', workerWallet.balance); 
 
     // Update task 
     await Task.findByIdAndUpdate(taskId, { 
       $set: { 
         status: 'completed', 
         finalStatus: 'COMPLETED', 
         paymentStatus: 'paid', 
         completedAt: new Date() 
       } 
     }); 
 
     // Update escrow 
     await Escrow.findOneAndUpdate( 
       { taskId: taskId }, 
       { 
         $set: { 
           status: 'released', 
           releasedAt: new Date() 
         } 
       } 
     ); 
 
     return res.json({ 
       success: true, 
       message: 'Payment released to worker!', 
       workerBalance: workerWallet.balance 
     }); 
 
   } catch (error) { 
     console.log('Release error:', error.message); 
     return res.status(500).json({ 
       success: false, 
       message: error.message 
     }); 
   } 
 }); 


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
  const { taskId } = req.params;
  const { userId } = req.body; // This should be the worker's ID

  try {
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });

    if (task.status !== 'pending_release') {
      return res.status(400).json({ message: 'Task is not pending release' });
    }

    const workerWallet = await Wallet.findOne({ userId });
    if (!workerWallet) return res.status(404).json({ message: 'Worker wallet not found' });

    workerWallet.balance += task.amount;
    await workerWallet.save();

    task.status = 'completed';
    task.finalStatus = 'COMPLETED';
    task.completedAt = new Date();
    await task.save();

    // Notify Provider and User
    await Notification.create({
      recipient: task.postedBy,
      sender: userId,
      title: 'Payment Released',
      message: `Payment of ₹${task.amount} for "${task.title}" has been released to the worker.`,
      type: 'PAYMENT_RELEASED',
      taskId: task._id
    });

    await Notification.create({
      recipient: userId,
      sender: task.postedBy,
      title: 'Payment Received',
      message: `₹${task.amount} has been added to your wallet for "${task.title}".`,
      type: 'PAYMENT_RECEIVED',
      taskId: task._id
    });

    res.json({ success: true, message: 'Escrow released successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
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
