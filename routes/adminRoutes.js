const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Task = require('../models/Task');
const Transaction = require('../models/Transaction');
const WithdrawalRequest = require('../models/WithdrawalRequest');

const Withdrawal = require('../models/Withdrawal');
const Escrow = require('../models/Escrow');
const Wallet = require('../models/Wallet');
const Notification = require('../models/Notification');

async function assertAdmin(req, res, next) {
  try {
    const adminId = req.header('x-admin-user-id') || req.query.adminId || (req.body && req.body.adminId);
    if (!adminId) return res.status(401).json({ success: false, message: 'AdminId required' });
    const u = await User.findById(adminId);
    if (!u || u.role !== 'admin') return res.status(403).json({ success: false, message: 'Admin access required' });
    if (u.status === 'BLOCKED') return res.status(403).json({ success: false, message: 'Admin account is blocked' });
    req.admin = u;
    next();
  } catch (e) {
    res.status(500).json({ success: false, message: e.message || 'Admin check failed' });
  }
}

router.use(assertAdmin);

router.get('/users', async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.json({ success: true, count: users.length, users });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.post('/users/:id/block', async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, { status: 'BLOCKED' }, { new: true }).select('-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, message: 'User blocked', user });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.post('/users/:id/activate', async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, { status: 'ACTIVE' }, { new: true }).select('-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, message: 'User activated', user });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.get('/tasks', async (req, res) => {
  try {
    const tasks = await Task.find()
      .populate('postedBy', 'name email')
      .populate('acceptedBy', 'name email');
    res.json({ success: true, count: tasks.length, tasks });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.delete('/tasks/:id', async (req, res) => {
  try {
    const t = await Task.findById(req.params.id);
    if (!t) return res.status(404).json({ success: false, message: 'Task not found' });
    await Task.deleteOne({ _id: t._id });
    res.json({ success: true, message: 'Task removed' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.get('/transactions', async (req, res) => {
  try {
    const items = await Transaction.find().sort({ created_at: -1 }).populate('user_id', 'name email');
    res.json({ success: true, count: items.length, transactions: items });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// --- WITHDRAWAL MANAGEMENT ---

// Admin gets all pending withdrawals
router.get('/withdrawals/pending', async (req, res) => {
  try {
    const pending = await Withdrawal.find({ status: 'pending' }).sort({ requestedAt: 1 });
    res.json({ success: true, withdrawals: pending });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Admin gets all withdrawals (completed, rejected, etc.)
router.get('/withdrawals/all', async (req, res) => {
  try {
    const all = await Withdrawal.find().sort({ requestedAt: -1 });
    res.json({ success: true, withdrawals: all });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Admin marks a withdrawal as processing
router.put('/withdrawals/process/:id', async (req, res) => {
  try {
    const { adminId, remarks } = req.body;
    const withdrawal = await Withdrawal.findByIdAndUpdate(
      req.params.id,
      {
        status: 'processing',
        processedBy: adminId,
        processedAt: new Date(),
        remarks
      },
      { new: true }
    );

    // Notify User
    await Notification.create({
      recipient: withdrawal.userId,
      title: '🔄 Withdrawal Processing',
      message: `Your withdrawal of ₹${withdrawal.amount} is being processed by our team.`,
      type: 'WITHDRAWAL_PROCESSING'
    });

    res.json({ success: true, message: 'Withdrawal marked as processing', withdrawal });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Admin marks a withdrawal as completed
router.put('/withdrawals/complete/:id', async (req, res) => {
  try {
    const { adminId, transactionReference, remarks } = req.body;

    const withdrawal = await Withdrawal.findByIdAndUpdate(
      req.params.id,
      {
        status: 'completed',
        transactionReference,
        remarks,
        completedAt: new Date(),
        processedBy: adminId
      },
      { new: true }
    );

    // Update wallet: decrease pendingWithdrawal
    await Wallet.findOneAndUpdate(
      { userId: withdrawal.userId },
      {
        $inc: { pendingWithdrawal: -withdrawal.amount },
        $push: {
          transactions: {
            type: 'withdrawal_completed',
            amount: withdrawal.amount,
            description: `Withdrawal to ${withdrawal.bankDetails.bankName} completed`,
            transactionReference,
            status: 'completed',
            date: new Date()
          }
        }
      }
    );

    // Notify User
    await Notification.create({
      recipient: withdrawal.userId,
      title: '✅ Withdrawal Completed',
      message: `₹${withdrawal.amount} has been successfully transferred to your bank account ending in ${withdrawal.bankDetails.accountNumber.slice(-4)}. Ref: ${transactionReference}`,
      type: 'WITHDRAWAL_COMPLETED'
    });

    res.json({ success: true, message: 'Withdrawal marked as completed' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Admin rejects a withdrawal
router.put('/withdrawals/reject/:id', async (req, res) => {
  try {
    const { adminId, reason } = req.body;

    const withdrawal = await Withdrawal.findById(req.params.id);

    // Refund amount back to user's main balance
    await Wallet.findOneAndUpdate(
      { userId: withdrawal.userId },
      {
        $inc: {
          balance: +withdrawal.amount, // Add back to main balance
          pendingWithdrawal: -withdrawal.amount // Deduct from pending balance
        },
        $push: {
          transactions: {
            type: 'withdrawal_rejected',
            amount: withdrawal.amount,
            description: `Withdrawal rejected. Reason: ${reason}`,
            status: 'failed',
            date: new Date()
          }
        }
      }
    );

    // Update withdrawal status
    await Withdrawal.findByIdAndUpdate(
      req.params.id,
      {
        status: 'rejected',
        rejectionReason: reason,
        rejectedAt: new Date(),
        processedBy: adminId
      }
    );

    // Notify User
    await Notification.create({
      recipient: withdrawal.userId,
      title: '❌ Withdrawal Rejected',
      message: `Your withdrawal of ₹${withdrawal.amount} was rejected. The amount has been refunded to your wallet. Reason: ${reason}`,
      type: 'WITHDRAWAL_REJECTED'
    });

    res.json({ success: true, message: 'Withdrawal rejected and amount refunded' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});


// --- DASHBOARD & ANALYTICS ---

router.get('/analytics/revenue', async (req, res) => {
  try {
    const pipeline = [
      {
        $group: {
          _id: '$type',
          total_amount: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      }
    ];
    const grouped = await Transaction.aggregate(pipeline);
    const totals = grouped.reduce((acc, g) => {
      acc[g._id] = { total: g.total_amount, count: g.count };
      return acc;
    }, {});
    res.json({
      success: true,
      revenue: {
        inflow: totals['CREDIT'] || { total: 0, count: 0 },
        outflow: totals['DEBIT'] || { total: 0, count: 0 },
        commission: totals['COMMISSION'] || { total: 0, count: 0 }
      }
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.get('/payouts', async (req, res) => {
  try {
    const Payout = require('../models/Payout');
    const status = req.query.status;
    const filter = status ? { status } : {};
    const items = await Payout.find(filter).sort({ created_at: -1 }).populate('user_id', 'name email');
    res.json({ success: true, count: items.length, payouts: items });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.get('/withdrawals', async (req, res) => {
  try {
    const status = req.query.status;
    const filter = status ? { status } : {};
    const items = await WithdrawalRequest.find(filter).sort({ created_at: -1 }).populate('user_id', 'name email');
    res.json({ success: true, count: items.length, withdrawals: items });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.post('/withdrawals/:id/approve', async (req, res) => {
  try {
    const w = await WithdrawalRequest.findById(req.params.id);
    if (!w) return res.status(404).json({ success: false, message: 'Withdrawal request not found' });
    if (w.status !== 'PENDING') return res.status(400).json({ success: false, message: 'Request already processed' });
    const user = await User.findById(w.user_id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    if (user.wallet < w.amount) return res.status(400).json({ success: false, message: 'Insufficient wallet balance' });
    user.wallet -= w.amount;
    await user.save();
    w.status = 'APPROVED';
    w.approved_at = new Date();
    w.approved_by = req.admin._id;
    await w.save();
    await Transaction.create({
      user_id: user._id,
      amount: w.amount,
      type: 'DEBIT',
      status: 'SUCCESS'
    });
    res.json({ success: true, message: 'Withdrawal approved' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.post('/withdrawals/:id/reject', async (req, res) => {
  try {
    const w = await WithdrawalRequest.findById(req.params.id);
    if (!w) return res.status(404).json({ success: false, message: 'Withdrawal request not found' });
    if (w.status !== 'PENDING') return res.status(400).json({ success: false, message: 'Request already processed' });
    w.status = 'PENDING';
    w.approved_at = new Date();
    w.approved_by = req.admin._id;
    await w.save();
    res.json({ success: true, message: 'Withdrawal rejected' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.get('/dashboard-summary', async (req, res) => {
  try {
    const users = await User.find().select('-password');
    const tasks = await Task.find()
      .populate('postedBy', 'name email')
      .populate('acceptedBy', 'name email');
    const withdrawals = await WithdrawalRequest.find().sort({ created_at: -1 }).populate('user_id', 'name email');
    const transactions = await Transaction.find().sort({ created_at: -1 });

    const pipeline = [
      {
        $group: {
          _id: '$type',
          total_amount: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      }
    ];
    const grouped = await Transaction.aggregate(pipeline);
    const totals = grouped.reduce((acc, g) => {
      acc[g._id] = { total: g.total_amount, count: g.count };
      return acc;
    }, {});

    res.json({
      success: true,
      users: { count: users.length, items: users },
      tasks: { count: tasks.length, items: tasks },
      withdrawals: { count: withdrawals.length, items: withdrawals },
      transactions: { count: transactions.length, items: transactions },
      revenue: {
        inflow: totals['CREDIT'] || { total: 0, count: 0 },
        outflow: totals['DEBIT'] || { total: 0, count: 0 },
        commission: totals['COMMISSION'] || { total: 0, count: 0 }
      }
    });
  } catch (e) {
    res.status(500).json({ success: false, message: 'Failed to fetch dashboard summary', error: e.message });
  }
});

// GET /admin/withdrawals - View all withdrawal requests
router.get('/withdrawals', async (req, res) => {
  try {
    const items = await Withdrawal.find().sort({ requestedAt: -1 }).populate('userId', 'name email').populate('bankAccountId');
    res.json({ success: true, count: items.length, withdrawals: items });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// PUT /admin/withdrawals/:id - Approve or reject withdrawal
router.put('/withdrawals/:id', async (req, res) => {
  try {
    const { status, remarks } = req.body;
    const item = await Withdrawal.findById(req.params.id);
    if (!item) return res.status(404).json({ success: false, message: 'Withdrawal not found' });
    
    item.status = status;
    item.remarks = remarks;
    if (status === 'completed') item.completedAt = Date.now();
    await item.save();

    // Update wallet transaction status
    const wallet = await Wallet.findOne({ userId: item.userId });
    if (wallet) {
      const tx = wallet.transactions.find(t => t.type === 'withdrawal' && t.status === 'pending' && t.amount === item.amount);
      if (tx) tx.status = status === 'completed' ? 'completed' : 'failed';
      
      // If rejected, refund the balance
      if (status === 'failed') {
        wallet.balance += item.amount;
        wallet.transactions.push({
          type: 'credit',
          amount: item.amount,
          description: 'Withdrawal refund due to rejection',
          status: 'completed'
        });
      }
      await wallet.save();
    }

    res.json({ success: true, message: `Withdrawal ${status}`, withdrawal: item });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// GET /admin/escrow - View all escrow transactions
router.get('/escrow', async (req, res) => {
  try {
    const items = await Escrow.find().sort({ heldAt: -1 }).populate('taskId').populate('providerId', 'name email').populate('userId', 'name email');
    res.json({ success: true, count: items.length, escrows: items });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// PUT /admin/dispute/:taskId - Resolve dispute
router.put('/dispute/:taskId', async (req, res) => {
  try {
    const { action, userId, amount } = req.body; // action: 'release' or 'refund' or 'split'
    const escrow = await Escrow.findOne({ taskId: req.params.taskId, status: 'disputed' });
    if (!escrow) return res.status(404).json({ success: false, message: 'Disputed escrow not found' });

    if (action === 'release') {
      // Release to user
      escrow.status = 'released';
      escrow.userId = userId || escrow.userId;
      escrow.releasedAt = Date.now();
      await escrow.save();
      
      const providerWallet = await Wallet.findOne({ userId: escrow.providerId });
      if (providerWallet) {
        providerWallet.escrowBalance -= escrow.amount;
        await providerWallet.save();
      }
      
      const workerWallet = await Wallet.findOne({ userId: escrow.userId });
      if (workerWallet) {
        workerWallet.balance += escrow.amount;
        workerWallet.transactions.push({
          type: 'credit',
          amount: escrow.amount,
          taskId: req.params.taskId,
          description: 'Payment released by admin after dispute',
          status: 'completed'
        });
        await workerWallet.save();
      }
    } else if (action === 'refund') {
      // Refund to provider
      escrow.status = 'refunded';
      escrow.refundedAt = Date.now();
      await escrow.save();
      
      const providerWallet = await Wallet.findOne({ userId: escrow.providerId });
      if (providerWallet) {
        providerWallet.escrowBalance -= escrow.amount;
        providerWallet.balance += escrow.amount;
        providerWallet.transactions.push({
          type: 'refund',
          amount: escrow.amount,
          taskId: req.params.taskId,
          description: 'Refunded by admin after dispute',
          status: 'completed'
        });
        await providerWallet.save();
      }
    }

    // Update task status to resolved
    const task = await Task.findByIdAndUpdate(req.params.taskId, { status: 'resolved' });

    // Notify involved parties
    if (task) {
      const recipientId = action === 'release' ? task.acceptedBy : task.postedBy;
      const message = action === 'release' 
        ? `The dispute for "${task.title}" has been resolved in your favor. Funds released.` 
        : `The dispute for "${task.title}" has been resolved. Funds refunded to your wallet.`;
      
      await Notification.create({
        recipient: recipientId,
        title: 'Dispute Resolved ✅',
        message: message,
        type: 'DISPUTE_RESOLVED',
        taskId: task._id
      });
    }

    res.json({ success: true, message: 'Dispute resolved' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;
