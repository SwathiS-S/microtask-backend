const express = require('express');
const router = express.Router();
const Task = require('../models/Task');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const ensureDir = (p) => { try { fs.mkdirSync(p, { recursive: true }); } catch (_) {} };
const samplesDir = path.join(__dirname, '..', 'uploads', 'samples');
ensureDir(samplesDir);
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, samplesDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname || '');
    cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
  }
});
const upload = multer({ storage });
// finals storage
const finalsDir = path.join(__dirname, '..', 'uploads', 'finals');
ensureDir(finalsDir);
const finalStorage = multer.diskStorage({
  destination: function (req, file, cb) { cb(null, finalsDir); },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname || '');
    cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
  }
});
const uploadFinal = multer({ storage: finalStorage });
const User = require('../models/User');
const Notification = require('../models/Notification');

// CREATE TASK
router.post('/create', async (req, res) => {
  try {
    console.log('CREATE TASK PAYLOAD:', req.body);
    const payload = {
      title: req.body.title,
      category: req.body.category || 'misc',
      description: req.body.description,
      amount: req.body.amount,
      postedBy: req.body.postedBy,
      // map optional fields for new model
      skillset: req.body.skillset,
      workType: req.body.workType || req.body.workMode || 'ALL',
      location: req.body.location,
      duration: req.body.duration
    };
    console.log('PAYLOAD TO SAVE:', payload);
    const task = new Task({ ...payload, status: 'draft' });
    await task.save();
    res.json({ success: true, message: 'Task created as draft', task });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

// GET DRAFT TASKS FOR PROVIDER
router.get('/drafts/:providerId', async (req, res) => {
  try {
    const drafts = await Task.find({ postedBy: req.params.providerId, status: 'draft' });
    res.json({ success: true, drafts });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET TASKS FOR A SPECIFIC PROVIDER
router.get('/provider/:providerId', async (req, res) => {
  try {
    const tasks = await Task.find({ postedBy: req.params.providerId })
      .populate('postedBy', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('applications.userId', 'name email');
    res.json({ success: true, tasks });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET ALL TASKS
router.get('/all', async (req, res) => {
  try {
    const tasks = await Task.find({ status: { $ne: 'draft' } })
      .populate('postedBy', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('applications.userId', 'name email');
    res.json(tasks);
  } catch (err) {
    res.status(500).json({ message: err.message || 'Failed to load tasks' });
  }
});

// USER APPLIES FOR TASK
router.post('/apply', async (req, res) => {
  const { taskId, userId } = req.body;
  try {
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    task.applications = task.applications || [];
    const exists = task.applications.find(a => String(a.userId) === String(userId));
    if (exists) return res.json({ message: 'Application already exists' });
    task.applications.push({ userId, state: 'APPLIED' });
    await task.save();

    // Notify Provider
    await Notification.create({
      recipient: task.postedBy,
      sender: userId,
      title: 'New Applicant',
      message: `A user has applied for your task: ${task.title}`,
      type: 'APPLICATION_RECEIVED',
      taskId: task._id
    });

    res.json({ message: 'Applied successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PROVIDER ACCEPTS APPLICATION
router.post('/applications/accept', async (req, res) => {
  const { taskId, userId, approvedBy } = req.body;
  try {
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    if (String(task.postedBy) !== String(approvedBy))
      return res.status(403).json({ message: 'Only the task provider can accept applications' });
    
    // Step 6: Sample work disappears forever
    task.applications = (task.applications || []).map(a => {
      if (String(a.userId) === String(userId)) {
        return { ...a.toObject(), state: 'ACCEPTED', sampleFile: undefined };
      }
      return { ...a.toObject(), sampleFile: undefined }; // Remove samples for others too
    });

    task.acceptedBy = userId;
    task.status = 'assigned';
    // deadlines
    task.approvedDate = new Date();
    const dur = Number(req.body.taskDurationDays || 3);
    task.taskDurationDays = dur;
    task.submissionDeadline = new Date(task.approvedDate.getTime() + dur * 24 * 60 * 60 * 1000);
    
    // Notify User
    await Notification.create({
      recipient: userId,
      sender: approvedBy,
      title: 'Application Approved! 🎉',
      message: `Your application for "${task.title}" has been approved. You can now start the task.`,
      type: 'APPLICATION_APPROVED',
      taskId: task._id
    });

    await task.save();
    res.json({ success: true, message: 'Application accepted and sample work removed' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// APPLY WITH SAMPLE FILE (Pending)
router.post('/:id/apply-with-sample', upload.single('sample'), async (req, res) => {
  try {
    const taskId = req.params.id;
    const { userId } = req.body;
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    task.applications = task.applications || [];
    const exists = task.applications.find(a => String(a.userId) === String(userId));
    if (exists) return res.status(400).json({ message: 'Already applied' });
    const file = req.file;
    const sampleFile = file ? {
      filename: file.filename,
      path: `/uploads/samples/${file.filename}`,
      mime: file.mimetype,
      size: file.size,
      uploadedAt: new Date()
    } : undefined;
    task.applications.push({ userId, state: 'APPLIED', sampleFile });
    await task.save();
    res.json({ success: true, message: 'Application submitted with sample', application: { userId, state: 'APPLIED', sampleFile } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE APPLICATION STATUS: APPROVE / REJECT / KEEP WAITING
router.post('/applications/status', async (req, res) => {
  try {
    const { taskId, userId, approvedBy, status } = req.body;
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    if (String(task.postedBy) !== String(approvedBy)) return res.status(403).json({ message: 'Only provider can update status' });
    task.applications = task.applications || [];
    const app = task.applications.find(a => String(a.userId) === String(userId));
    if (!app) return res.status(404).json({ message: 'Application not found' });
    if (status === 'APPROVED') {
      app.state = 'ACCEPTED';
      // Notify User
      await Notification.create({
        recipient: userId,
        sender: approvedBy,
        title: 'Application Approved! 🎉',
        message: `Your application for "${task.title}" has been approved. You can now start the task.`,
        type: 'APPLICATION_APPROVED',
        taskId: task._id
      });
    } else if (status === 'REJECTED') {
      app.state = 'REJECTED';
      // Notify User
      await Notification.create({
        recipient: userId,
        sender: approvedBy,
        title: 'Application Rejected',
        message: `Your application for "${task.title}" was not selected this time.`,
        type: 'APPLICATION_REJECTED',
        taskId: task._id
      });
    } else app.state = 'APPLIED'; // KEEP WAITING
    await task.save();
    res.json({ success: true, message: 'Application status updated', state: app.state });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// USER SUBMITS FINAL WORK (before deadline, only once)
router.post('/:id/submit-final', uploadFinal.single('final'), async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ message: 'userId required' });
    if (String(task.acceptedBy) !== String(userId)) return res.status(403).json({ message: 'Only accepted user can submit final' });
    if (task.finalFile && task.finalFile.filename) return res.status(400).json({ message: 'Final already submitted' });
    const now = new Date();
    if (task.submissionDeadline && now > task.submissionDeadline) {
      task.finalStatus = 'MISSED';
      await task.save();
      return res.status(400).json({ message: 'Deadline missed' });
    }
    const file = req.file;
    if (!file) return res.status(400).json({ message: 'Final file required' });
    task.finalFile = {
      filename: file.filename,
      path: `/uploads/finals/${file.filename}`,
      mime: file.mimetype,
      size: file.size,
      uploadedAt: new Date()
    };
    task.finalStatus = 'SUBMITTED';
    task.status = 'submitted';
    await task.save();

    // Notify Provider
    await Notification.create({
      recipient: task.postedBy,
      sender: userId,
      title: 'Final Work Submitted',
      message: `Final work for "${task.title}" has been submitted for your review.`,
      type: 'WORK_SUBMITTED',
      taskId: task._id
    });

    res.json({ success: true, message: 'Final work submitted for review', finalFile: task.finalFile });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PROVIDER REJECTS FINAL WORK (optional remarks)
router.post('/reject-final', async (req, res) => {
  try {
    const { taskId, approvedBy, remark } = req.body;
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    if (String(task.postedBy) !== String(approvedBy))
      return res.status(403).json({ message: 'Only the task provider can reject final work' });
    task.finalStatus = 'REJECTED';
    task.status = 'rejected';
    task.reviewRemark = remark || '';
    await task.save();
    res.json({ success: true, message: 'Final work rejected' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PROVIDER APPROVES FINAL WORK (Step 9 & 10)
router.post('/approve-final', async (req, res) => {
  const { taskId, providerId } = req.body;
  try {
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });
    if (String(task.postedBy) !== String(providerId)) return res.status(403).json({ success: false, message: 'Only provider can approve' });
    if (task.status !== 'submitted') return res.status(400).json({ success: false, message: 'Task not submitted' });

    const Escrow = require('../models/Escrow');
    const Wallet = require('../models/Wallet');
    const Transaction = require('../models/Transaction');

    // 1. Find Escrow Record
    const escrow = await Escrow.findOne({ taskId: task._id, status: 'held' });
    if (!escrow) return res.status(404).json({ success: false, message: 'No funds held in escrow' });

    // 2. Transfer to Worker Wallet
    const worker = await User.findById(task.acceptedBy);
    if (!worker) return res.status(404).json({ success: false, message: 'Worker not found' });

    let workerWallet = await Wallet.findOne({ userId: worker._id });
    if (!workerWallet) workerWallet = new Wallet({ userId: worker._id, role: 'user', balance: 0 });
    
    workerWallet.balance = (workerWallet.balance || 0) + escrow.amount;
    workerWallet.transactions.push({
      type: 'credit',
      amount: escrow.amount,
      taskId: task._id,
      taskTitle: task.title,
      description: `Payment released for Task: ${task.title}`,
      status: 'completed',
      date: new Date()
    });
    await workerWallet.save();

    // 3. Update Escrow Status
    escrow.status = 'released';
    escrow.releasedAt = new Date();
    await escrow.save();

    // 4. Update Provider's Escrow Balance
    const providerWallet = await Wallet.findOne({ userId: task.postedBy });
    if (providerWallet) {
      providerWallet.escrowBalance = Math.max(0, (providerWallet.escrowBalance || 0) - escrow.amount);
      providerWallet.transactions.push({
        type: 'escrow_release',
        amount: escrow.amount,
        taskId: task._id,
        taskTitle: task.title,
        description: `Payment released to worker for Task: ${task.title}`,
        status: 'completed',
        date: new Date()
      });
      await providerWallet.save();
    }

    // 5. Update Task Status (Step 11)
    task.status = 'completed';
    task.finalStatus = 'APPROVED';
    await task.save();

    // 6. Notify Worker
    await Notification.create({
      recipient: worker._id,
      sender: providerId,
      title: 'Payment Released! 💰',
      message: `Your work for "${task.title}" has been approved and ₹${escrow.amount} has been added to your wallet.`,
      type: 'PAYMENT_RELEASED',
      taskId: task._id
    });

    res.json({ success: true, message: 'Work approved and payment released to worker wallet' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// LIST APPLICATIONS FOR A TASK
router.get('/:id/applications', async (req, res) => {
  try {
    const task = await Task.findById(req.params.id).populate('applications.userId', 'name email');
    if (!task) return res.status(404).json({ message: 'Task not found' });
    res.json({ success: true, applications: task.applications || [] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// USER SUBMITS WORK (set submitted)
router.post('/submit', async (req, res) => {
  const { taskId, submittedBy } = req.body;
  try {
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    if (!task.acceptedBy) return res.status(400).json({ message: 'Task not accepted yet' });
    if (String(task.acceptedBy) !== String(submittedBy)) return res.status(403).json({ message: 'Only assigned user can submit' });
    if (!['assigned','in_progress'].includes(task.status)) return res.status(400).json({ message: 'Task not in progress' });
    task.status = 'submitted';
    await task.save();
    res.json({ success: true, message: 'Work submitted for review' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// USER STARTS TASK (moves to in_progress)
router.post('/:id/start', async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });
    const { userId } = req.body;
    if (String(task.acceptedBy) !== String(userId)) return res.status(403).json({ success: false, message: 'Only assigned user can start' });
    if (task.status !== 'assigned') return res.status(400).json({ success: false, message: 'Task not in assigned state' });
    task.status = 'in_progress';
    await task.save();
    res.json({ success: true, message: 'Task started' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PROVIDER REVIEWS WORK (moves to reviewed)
router.post('/:id/review', async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });
    const { providerId } = req.body;
    if (String(task.postedBy) !== String(providerId)) return res.status(403).json({ success: false, message: 'Only provider can review' });
    if (task.status !== 'submitted') return res.status(400).json({ success: false, message: 'Task not submitted' });
    task.status = 'reviewed';
    await task.save();
    res.json({ success: true, message: 'Task marked as reviewed' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// STATUS UPDATE (daily progress note)
router.post('/:id/status-update', async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    const { userId, text } = req.body;
    if (!userId || !text) return res.status(400).json({ message: 'userId and text required' });
    if (!task.acceptedBy) return res.status(400).json({ message: 'No assignee for this task' });
    if (String(task.acceptedBy) !== String(userId)) return res.status(403).json({ message: 'Only the assignee can post updates' });
    task.updates = task.updates || [];
    task.updates.unshift({ userId, text });
    await task.save();

    // Notify Provider
    await Notification.create({
      recipient: task.postedBy,
      sender: userId,
      title: 'Task Update Received',
      message: `The worker has submitted a daily update for: ${task.title}`,
      type: 'UPDATE_SUBMITTED',
      taskId: task._id
    });

    res.json({ success: true, message: 'Update saved' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET TASK UPDATES
router.get('/:id/updates', async (req, res) => {
  try {
    const task = await Task.findById(req.params.id).populate('updates.userId', 'name email');
    if (!task) return res.status(404).json({ message: 'Task not found' });
    res.json({ success: true, updates: task.updates || [] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// COMPLETE TASK & TRANSFER PAYMENT (worker marks done – optional flow)
router.post('/complete', async (req, res) => {
  const { taskId, completedBy } = req.body;

  try {
    const task = await Task.findById(taskId);

    if (!task)
      return res.status(404).json({ message: 'Task not found' });

    if (!task.acceptedBy)
      return res.status(400).json({ message: 'Task not accepted yet' });

    if (task.acceptedBy.toString() !== completedBy)
      return res.status(400).json({ message: 'Only assigned user can complete' });

    if (!['accepted', 'underReview'].includes(task.status))
      return res.status(400).json({ message: 'Task not in accepted state' });

    task.status = 'completed';
    await task.save();

    const poster = await User.findById(task.postedBy);
    const worker = await User.findById(completedBy);

    // Calculate Commission (20%)
    const adminCommission = Math.round(task.amount * 0.20);
    const userEarnings = task.amount - adminCommission;

    if (poster.wallet < task.amount)
      return res.status(400).json({ message: 'Insufficient balance' });

    // Deduct from poster
    poster.wallet -= task.amount;
    // Credit to worker
    worker.wallet += userEarnings;

    await poster.save();
    await worker.save();

    // Credit to Admin
    const admin = await User.findOne({ role: 'admin' });
    if (admin) {
      admin.wallet = (admin.wallet || 0) + adminCommission;
      await admin.save();
      
      // Admin Commission Transaction
      const Transaction = require('../models/Transaction');
      await Transaction.create({
        user_id: admin._id,
        task_id: task._id,
        amount: adminCommission,
        type: 'COMMISSION',
        status: 'SUCCESS'
      });
    }

    // Transactions for poster and worker
    const Transaction = require('../models/Transaction');
    await Transaction.create({
      user_id: poster._id,
      task_id: task._id,
      amount: task.amount,
      type: 'DEBIT',
      status: 'SUCCESS'
    });

    await Transaction.create({
      user_id: worker._id,
      task_id: task._id,
      amount: userEarnings,
      type: 'CREDIT',
      status: 'SUCCESS'
    });

    res.json({ 
      message: 'Task completed and payment transferred successfully',
      earnings: userEarnings,
      commission: adminCommission
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/approve-work/:taskId', async (req, res) => {
  const { taskId } = req.params;
  const { approvedBy } = req.body;

  try {
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });

    if (String(task.postedBy) !== String(approvedBy)) {
      return res.status(403).json({ message: 'Only the task provider can approve this work' });
    }

    task.status = 'pending_release';
    task.providerApprovedAt = new Date();
    await task.save();

    // Notify Admin
    const admin = await User.findOne({ role: 'admin' });
    if (admin) {
      await Notification.create({
        recipient: admin._id,
        sender: approvedBy,
        title: 'Escrow Release Request',
        message: `Provider approved work for "${task.title}". Please release the escrow of ₹${task.amount}.`,
        type: 'ESCROW_RELEASE_REQUEST',
        taskId: task._id
      });
    }

    res.json({ success: true, message: 'Work approved! Admin will release payment shortly.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// APPROVE TASK (provider approves → marks as approved → returns Razorpay order)
router.post('/approve', async (req, res) => {
  const { taskId, approvedBy } = req.body;
  console.log('POST /tasks/approve', { taskId, approvedBy });

  try {
    if (!taskId || !approvedBy)
      return res.status(400).json({ message: 'taskId and approvedBy are required' });

    const task = await Task.findById(String(taskId));

    if (!task)
      return res.status(404).json({ message: 'Task not found' });

    if (!['submitted', 'accepted', 'inProgress', 'underReview'].includes(task.status))
      return res.status(400).json({ message: 'Task is not ready for approval' });

    if (String(task.postedBy) !== String(approvedBy))
      return res.status(403).json({ message: 'Only the task provider can approve this task' });

    if (!task.acceptedBy)
      return res.status(400).json({ message: 'Task not accepted by anyone yet' });

    // Mark as approved (waiting for payment)
    task.status = 'reviewed';
    task.finalStatus = 'APPROVED';
    await task.save();

    // Create Razorpay Order
    const { createOrder } = require('../services/razorpay');
    const orderRes = await createOrder(task.amount, `task_pay_${task._id}`);

    if (!orderRes.ok) {
      return res.status(500).json({ success: false, message: 'Failed to create Razorpay order', error: orderRes.error });
    }

    res.json({
      success: true,
      message: 'Task approved. Please complete the payment.',
      order: orderRes.data,
      amount: task.amount,
      taskId: task._id
    });
  } catch (err) {
    console.error('Approve error:', err);
    res.status(500).json({ message: err.message || 'Server error' });
  }
});

// DECLINE TASK (task provider declines → user can continue work)
router.post('/decline', async (req, res) => {
  const { taskId, declinedBy } = req.body;

  try {
    const task = await Task.findById(taskId);

    if (!task)
      return res.status(404).json({ message: 'Task not found' });

    if (!['accepted','submitted','inProgress','underReview'].includes(task.status))
      return res.status(400).json({ message: 'Task is not in reviewable state' });

    if (task.postedBy.toString() !== declinedBy)
      return res.status(403).json({ message: 'Only the task provider can decline this task' });

    task.status = 'inProgress';
    await task.save();

    res.json({ message: 'Task rejected, please continue working' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// CANCEL TASK
router.post('/cancel', async (req, res) => {
  const { taskId, cancelledBy } = req.body;
  try {
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });
    if (String(task.postedBy) !== String(cancelledBy)) return res.status(403).json({ message: 'Only provider can cancel' });
    if (task.status === 'open' || task.status === 'created') {
      task.status = 'cancelled';
    } else if (['accepted','inProgress','submitted','underReview'].includes(task.status)) {
      task.status = 'cancelled';
      // leave acceptedBy as is for audit
    } else {
      return res.status(400).json({ message: 'Task cannot be cancelled in current state' });
    }
    await task.save();
    res.json({ message: 'Task cancelled' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
