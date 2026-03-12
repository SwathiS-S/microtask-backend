const express = require('express');
const router = express.Router();
const Escrow = require('../models/Escrow');
const Wallet = require('../models/Wallet');
const Task = require('../models/Task');
const Notification = require('../models/Notification');

// Fix 2: Admin dashboard fetch all pending escrows
router.get('/admin/escrow/pending', async (req, res) => { 
   try { 
     // Remove adminId check completely 
     // Just return pending tasks 
 
     const pendingTasks = await Task.find({ 
       status: 'pending_release' 
     }); 
 
     const pendingEscrows = await Escrow.find({ 
       status: 'held' 
     }).populate('taskId').populate('providerId'); 
 
     console.log('Pending tasks:', pendingTasks.length); 
     console.log('Pending escrows:', pendingEscrows.length); 
 
     return res.json({ 
       success: true, 
       tasks: pendingTasks, 
       escrows: pendingEscrows 
     }); 
 
   } catch (error) { 
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
 
     console.log('=== RELEASE START ==='); 
     console.log('taskId:', taskId); 
 
     // Try finding task directly first 
     let task = await Task.findById(taskId); 
 
     // If not found try finding via escrow 
     if (!task) { 
       const escrowRecord = await Escrow.findById(taskId); 
       console.log('Found escrow record as ID:', escrowRecord); 
       if (escrowRecord) { 
         task = await Task.findById(escrowRecord.taskId); 
       } 
     } 
 
     if (!task) { 
       return res.status(404).json({ 
         success: false, 
         message: 'Task not found' 
       }); 
     } 
 
     console.log('Task:', task.title); 
     console.log('acceptedBy:', task.acceptedBy); 
     console.log('amount:', task.amount); 
 
     console.log('Full task object:', JSON.stringify(task)); 
 
     let workerId = task.acceptedBy 
       || task.assignedTo 
       || task.assignedUser 
       || task.workerId 
       || task.selectedWorker; 
 
     console.log('workerId found:', workerId); 
 
     if (!workerId) { 
       // Search in applications array 
       const acceptedApp = task.applications?.find( 
         app => app.status === 'accepted' 
           || app.status === 'ACCEPTED' 
           || app.isAccepted === true 
       ); 
 
       console.log('Accepted application:', acceptedApp); 
 
       if (!acceptedApp) { 
         return res.status(400).json({ 
           success: false, 
           message: 'No worker found in task' 
         }); 
       } 
 
       const workerIdFromApp = acceptedApp.userId 
         || acceptedApp.user 
         || acceptedApp.workerId; 
 
       console.log('Worker from application:', workerIdFromApp); 
 
       // Use worker from application 
       // Continue with workerIdFromApp 
       workerId = workerIdFromApp; 
     } 
 
     // Get escrow 
     const escrow = await Escrow.findOne({ 
       taskId: task._id 
     }); 
     console.log('Escrow:', escrow?.amount); 
 
     // Calculate worker amount 
     const totalAmount = Number( 
       escrow?.amount || task.amount 
     ); 
     const workerAmount = escrow?.workerAmount 
       || Math.round(totalAmount * 0.8); 
 
     console.log('Worker amount:', workerAmount); 
 
     // Step 1: Credit worker wallet 
     const workerWallet = await Wallet.findOneAndUpdate( 
       { userId: workerId }, 
       { 
         $inc: { balance: Number(workerAmount) }, 
         $push: { 
           transactions: { 
             type: 'credit', 
             amount: Number(workerAmount), 
             taskId: task._id, 
             description: `Payment ₹${workerAmount} released from escrow`, 
             status: 'completed', 
             date: new Date() 
           } 
         } 
       }, 
       { upsert: true, new: true } 
     ); 
 
     console.log('Worker balance:', workerWallet.balance); 
 
     // Step 2: Update admin outflow 
     await Wallet.findOneAndUpdate( 
       { role: 'admin' }, 
       { 
         $inc: { totalOutflow: Number(workerAmount) }, 
         $push: { 
           transactions: { 
             type: 'escrow_release', 
             amount: Number(workerAmount), 
             taskId: task._id, 
             description: `Released ₹${workerAmount} to worker`, 
             status: 'completed', 
             date: new Date() 
           } 
         } 
       }, 
       { upsert: true, new: true } 
     ); 
 
     // Step 3: Update task to completed 
     await Task.findByIdAndUpdate(task._id, { 
       $set: { 
         status: 'completed', 
         finalStatus: 'COMPLETED', 
         paymentStatus: 'paid', 
         completedAt: new Date() 
       } 
     }); 
 
     console.log('Task → completed'); 
 
     // Step 4: Update escrow to released 
     if (escrow) { 
       await Escrow.findOneAndUpdate( 
         { taskId: task._id }, 
         { 
           $set: { 
             status: 'released', 
             releasedAt: new Date() 
           } 
         } 
       ); 
     } 
 
     console.log('=== RELEASE DONE ==='); 
 
     return res.json({ 
       success: true, 
       message: 'Payment released!', 
       workerBalance: workerWallet.balance, 
       workerAmount: workerAmount 
     }); 
 
   } catch (error) { 
     console.log('ERROR:', error.message); 
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
            type: 'credit', 
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
