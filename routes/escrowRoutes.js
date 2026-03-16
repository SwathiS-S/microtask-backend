const express = require('express');
const router = express.Router();
const Escrow = require('../models/Escrow');
const Wallet = require('../models/Wallet');
const Task = require('../models/Task');
const Notification = require('../models/Notification');
const User = require('../models/User');
const Transaction = require('../models/Transaction');

// Fix 2: Admin dashboard fetch all pending escrows
router.get('/pending', async (req, res) => {
  try {
    const escrows = await Escrow.find({ status: 'held' })
      .populate('taskId', 'title amount workerAmount status acceptedBy')
      .populate('userId', 'name email')
      .populate('providerId', 'name email');

    res.json({ success: true, escrows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/release/:id', async (req, res) => { 
   try { 
     const { id } = req.params; 
 
     console.log('=== RELEASE START ==='); 
     console.log('Called with ID:', id); 
 
     // 1. Find the escrow first
     const escrow = await Escrow.findById(id);
     if (!escrow) {
       console.log('Escrow not found by ID:', id);
       return res.status(404).json({ success: false, message: 'Escrow not found' });
     }
     console.log('Escrow found, status:', escrow.status);
     console.log('Task ID from escrow:', escrow.taskId);

     // 2. Find the task using escrow.taskId
     const task = await Task.findById(escrow.taskId); 
     if (!task) { 
       console.log('Task not found for escrow taskId:', escrow.taskId);
       return res.status(404).json({ 
         success: false, 
         message: 'Task not found' 
       }); 
     } 
 
     console.log('Task found:', task.title); 
     console.log('acceptedBy:', task.acceptedBy); 
     console.log('amount:', task.amount); 
 
     // 3. Find the worker (User who should receive the payment)
     let workerId = task.acceptedBy 
       || task.assignedTo 
       || task.assignedUser 
       || task.workerId 
       || task.selectedWorker 
       || escrow.userId; // Fallback to escrow.userId if task fields are missing

     console.log('workerId found:', workerId); 
 
     if (!workerId) { 
       // Search in applications array if any
       const acceptedApp = task.applications?.find( 
         app => app.status === 'accepted' 
           || app.status === 'ACCEPTED' 
           || app.isAccepted === true 
       ); 
 
       if (acceptedApp) {
         workerId = acceptedApp.userId || acceptedApp.user || acceptedApp.workerId;
         console.log('Worker found from application:', workerId);
       }
     } 

     if (!workerId) {
       return res.status(400).json({
         success: false,
         message: 'No worker found for this task'
       });
     }

     // 4. Calculate worker amount 
     const totalAmount = Number(escrow.amount || task.amount || 0); 
     const workerAmount = Number(escrow.workerAmount || Math.round(totalAmount * 0.8)); 
 
     console.log('Worker amount to release:', workerAmount);

     // Step 1: Credit worker wallet 
    const workerWallet = await Wallet.findOneAndUpdate( 
      { userId: workerId }, 
      { 
        $inc: { balance: Number(workerAmount) }, 
        $push: { 
          transactions: { 
            transactionType: 'credit', 
            amount: Number(workerAmount), 
            taskId: task._id, 
            description: `Payment ₹${workerAmount} released from escrow for task: ${task.title}`, 
            status: 'completed', 
            date: new Date()
          } 
        } 
      },
      { new: true, upsert: true }
    ); 

    // Step 2: Update escrow status
    escrow.status = 'released';
    escrow.releasedAt = new Date();
    await escrow.save();

    // Step 3: Update task status if needed
    if (task.status !== 'paid') {
      task.status = 'paid';
      await task.save();
    }

    // Step 4: Notify User
    try {
      await Notification.create({
        recipient: workerId,
        title: '💰 Payment Released',
        message: `Payment of ₹${workerAmount} has been released to your wallet for task: ${task.title}`,
        type: 'PAYMENT_RELEASED'
      });
    } catch (err) {
      console.error('Notification failed:', err);
    }

    res.json({ 
      success: true, 
      message: 'Payment released successfully to worker',
      workerAmount,
      workerId
    });

  } catch (error) {
    console.error('RELEASE ERROR:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}); 


router.post('/deposit/:taskId', async (req, res) => { 
   try { 
     const { providerId, amount } = req.body; 
 
     const wallet = await Wallet.findOne({ userId: providerId }); 
     if (!wallet || wallet.balance < amount) { 
       return res.status(400).json({ success: false, message: 'Insufficient balance' }); 
     } 
 
     wallet.balance -= amount; 
     wallet.escrowBalance += amount; 
     wallet.transactions.push({ 
       transactionType: 'escrow_hold', // ✅ use transactionType not type 
       amount, 
       taskId: req.params.taskId, 
       description: 'Funds held in escrow for task', 
       status: 'completed' 
     }); 
     await wallet.save(); 

     // Sync with User model wallet field
     await User.findByIdAndUpdate(providerId, { $inc: { wallet: -Number(amount) } });

     // Sync with Transaction collection (Old system)
     await Transaction.create({
       user_id: providerId,
       task_id: req.params.taskId,
       amount: Number(amount),
       type: 'ESCROW_HOLD',
       status: 'SUCCESS',
       description: 'Funds held in escrow for task',
       created_at: new Date()
     });
 
     // ✅ Compute and store workerAmount at creation time 
     const workerAmount = Math.round(Number(amount) * 0.8); 
     const platformFee  = Number(amount) - workerAmount; 
 
     const escrow = new Escrow({ 
       taskId: req.params.taskId, 
       providerId, 
       amount: Number(amount), 
       workerAmount: workerAmount,  // ✅ stored now 
       platformFee: platformFee, 
       totalPaid: Number(amount), 
       status: 'held' 
     }); 
     await escrow.save(); 
 
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

    const escrow = await Escrow.findOne({ 
      taskId: task._id, 
      status: 'held' 
    }); 
    const releaseAmount = escrow?. workerAmount 
      || Math.round(Number(task.amount) * 0.8); 
    
    await Wallet.findOneAndUpdate( 
      { userId }, 
      { 
        $inc: { balance: Number(releaseAmount) }, 
        $push: { 
          transactions: { 
            transactionType: 'credit', 
            amount: Number(releaseAmount), 
            taskId: task._id, 
            description: 'Payment released from escrow', 
            status: 'completed', 
            date: new Date() 
          } 
        } 
      }, 
      { upsert: true, new: true } 
    ); 

    // Sync with User model wallet field
    await User.findByIdAndUpdate(userId, { $inc: { wallet: Number(releaseAmount) } });

    // Sync with Transaction collection (Old system)
    await Transaction.create({
      user_id: userId,
      task_id: task._id,
      task_title: task.title,
      taskTitle: task.title,
      amount: Number(releaseAmount),
      type: 'CREDIT',
      status: 'SUCCESS',
      description: 'Payment released from escrow',
      created_at: new Date()
    });
    
    if (escrow) { 
      await Wallet.findOneAndUpdate( 
        { userId: escrow.providerId }, 
        { $inc: { escrowBalance: -Number(escrow.amount) } } 
      ); 
      await Escrow.findOneAndUpdate( 
        { taskId: task._id }, 
        { $set: { status: 'released', releasedAt: new Date() } } 
      ); 
    } 

    task.status = 'completed';
    task.finalStatus = 'COMPLETED';
    task.completedAt = new Date();
    await task.save();

    // Notify Provider and User
    await Notification.create({
      recipient: task.postedBy,
      sender: userId,
      title: 'Payment Released',
      message: `Payment of ₹${releaseAmount} for "${task.title}" has been released to the worker.`,
      type: 'PAYMENT_RELEASED',
      taskId: task._id
    });

    await Notification.create({
      recipient: userId,
      sender: task.postedBy,
      title: 'Payment Received',
      message: `₹${releaseAmount} has been added to your wallet for "${task.title}".`,
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
        transactionType: 'refund',
        amount: escrow.amount,
        taskId: req.params.taskId,
        description: 'Escrow refunded to wallet',
        status: 'completed'
      });
      await providerWallet.save();

      // Sync with User model wallet field
      await User.findByIdAndUpdate(escrow.providerId, { $inc: { wallet: Number(escrow.amount) } });

      // Sync with Transaction collection (Old system)
      await Transaction.create({
        user_id: escrow.providerId,
        task_id: req.params.taskId,
        amount: Number(escrow.amount),
        type: 'REFUND',
        status: 'SUCCESS',
        description: 'Escrow refunded to wallet',
        created_at: new Date()
      });
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
