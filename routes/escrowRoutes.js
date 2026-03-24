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
      .populate('providerId', 'name email')
      .populate('userId', 'name email')
      .populate({
        path: 'taskId',
        model: 'Task', // Explicitly specify the model name as part of the trick
        select: 'title amount acceptedBy assignedTo applications',
        populate: {
          path: 'acceptedBy',
          model: 'User',
          select: 'name email'
        }
      });

    // Ensure we handle case where taskId might not be populated or deleted
    const sanitizedEscrows = escrows.map(esc => {
      const e = esc.toObject();
      if (!e.taskId) {
        // Task was deleted, use redundant title
        e.taskTitle = e.taskTitle || 'Untitled Task (Deleted)';
      }
      return e;
    });

    res.json({ success: true, escrows: sanitizedEscrows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/release/:id', async (req, res) => {
  try {
    const escrow = await Escrow.findById(req.params.id);
    if (!escrow) return res.status(404).json({ success: false, message: 'Escrow not found' });

    // Get task if exists, but don't fail if deleted
    const task = await Task.findById(escrow.taskId);
    const taskTitle = task?.title || 'Deleted Task';
    
    // Get amount with fallbacks 
    const totalAmount = Number(escrow.amount) || 
                       Number(escrow.totalAmount) || 
                       Number(task?.amount) || 
                       Number(task?.budget) || 
                       Number(task?.price) || 0; 
 
    console.log('escrow.amount:', escrow.amount); 
    console.log('task.amount:', task?.amount); 
    console.log('totalAmount resolved:', totalAmount); 
 
    if (totalAmount === 0) { 
      return res.status(400).json({ 
        success: false, 
        message: 'Cannot release: Escrow amount is missing or zero' 
      }); 
    } 
 
    const workerAmount = totalAmount * 0.8; 
    const adminCommission = totalAmount * 0.2; 

    // Get worker ID from escrow or task
    let workerId = escrow.userId || escrow.workerId || task?.acceptedBy || task?.assignedTo;
    
    // If workerId is a populated object, extract the ID
    if (workerId && typeof workerId === 'object' && workerId._id) {
      workerId = workerId._id;
    }

    if (!workerId) return res.status(400).json({ success: false, message: 'Worker not found for this escrow' });

    // Save workerId back to escrow for future reference 
    await Escrow.findByIdAndUpdate(escrow._id, { userId: workerId }); 

    // Credit worker wallet
    await Wallet.findOneAndUpdate(
      { userId: workerId },
      {
        $inc: { balance: workerAmount },
        $push: {
          transactions: {
            transactionType: 'credit',
            amount: workerAmount,
            taskId: escrow.taskId,
            description: `Payment ₹${workerAmount} released from escrow for: ${taskTitle}`,
            status: 'completed',
            date: new Date()
          }
        },
        $setOnInsert: { role: 'user', userId: workerId }
      },
      { upsert: true, new: true }
    );

    // Debit provider wallet transaction history
    if (escrow.providerId) {
      await Wallet.findOneAndUpdate(
        { userId: escrow.providerId },
        {
          $push: {
            transactions: {
              transactionType: 'escrow_release',
              amount: workerAmount,
              taskId: escrow.taskId,
              description: `Payment ₹${workerAmount} released to worker for: ${taskTitle}`,
              status: 'completed',
              date: new Date()
            }
          }
        }
      );
    }

    // Update escrow status
    await Escrow.findByIdAndUpdate(escrow._id, { status: 'released', releasedAt: new Date() });

    // Sync Transaction collection
    await Transaction.create({
      user_id: workerId,
      task_id: escrow.taskId,
      taskTitle: taskTitle,
      amount: workerAmount,
      type: 'credit',
      status: 'SUCCESS',
      created_at: new Date()
    });

    // Update user wallet balance in User model
    await User.findByIdAndUpdate(workerId, { $inc: { wallet: workerAmount } });

    res.json({ success: true, message: `Payment of ₹${workerAmount} released successfully!` });
  } catch (e) {
    console.error('Release error:', e);
    res.status(500).json({ success: false, message: e.message });
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

// POST /api/admin/escrow/cancel/:taskId - Cancel task and refund provider 
router.post('/cancel/:taskId', async (req, res) => { 
  try { 
    const { taskId } = req.params; 
    
    const task = await Task.findById(taskId); 
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' }); 
    
    // Only allow cancellation if no worker assigned yet 
    const hasWorker = task.acceptedBy || task.assignedTo || 
                      task.applications?.some(a => 
                        ['accepted','approved'].includes((a.status||'').toLowerCase()) 
                      ); 
    
    if (hasWorker) { 
      return res.status(400).json({ 
        success: false, 
        message: 'Cannot cancel task — a worker has already been assigned. Please resolve with the worker first.' 
      }); 
    } 
    
    // Find escrow 
    const escrow = await Escrow.findOne({ taskId, status: 'held' }); 
    if (!escrow) { 
      // No escrow found, just cancel the task 
      await Task.findByIdAndUpdate(taskId, { status: 'cancelled' }); 
      return res.json({ success: true, message: 'Task cancelled. No escrow found to refund.' }); 
    } 
    
    const refundAmount = Number(escrow.amount) || Number(escrow.totalAmount) || Number(task.amount) || 0; 
    const providerId = escrow.providerId || task.createdBy || task.providerId; 
    
    if (!providerId) { 
      return res.status(400).json({ success: false, message: 'Provider not found for refund' }); 
    } 
    
    // Refund to provider wallet 
    await Wallet.findOneAndUpdate( 
      { userId: providerId }, 
      { 
        $inc: { balance: Number(refundAmount) }, 
        $push: { 
          transactions: { 
            transactionType: 'refund', 
            amount: Number(refundAmount), 
            taskId: task._id, 
            description: `Refund ₹${refundAmount} for cancelled task: ${task.title}`, 
            status: 'completed', 
            date: new Date() 
          } 
        }, 
        $setOnInsert: { role: 'provider', userId: providerId } 
      }, 
      { upsert: true, new: true } 
    ); 
    
    // Update provider User model balance 
    await User.findByIdAndUpdate(providerId, { $inc: { wallet: Number(refundAmount) } }); 
    
    // Update escrow status 
    await Escrow.findByIdAndUpdate(escrow._id, { status: 'refunded' }); 
    
    // Cancel the task 
    await Task.findByIdAndUpdate(taskId, { status: 'cancelled' }); 
    
    // Sync Transaction collection 
    await Transaction.create({ 
      user_id: providerId, 
      task_id: task._id, 
      taskTitle: task.title, 
      amount: Number(refundAmount), 
      type: 'refund', 
      status: 'SUCCESS', 
      description: `Refund for cancelled task: ${task.title}`, 
      created_at: new Date() 
    }); 
    
    res.json({ 
      success: true, 
      message: `Task cancelled and ₹${refundAmount} refunded to your wallet!` 
    }); 
  } catch(e) { 
    console.error('Cancel task error:', e); 
    res.status(500).json({ success: false, message: e.message }); 
  } 
});

module.exports = router;
