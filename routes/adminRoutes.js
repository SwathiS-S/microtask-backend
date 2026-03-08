const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Task = require('../models/Task');
const Transaction = require('../models/Transaction');
const WithdrawalRequest = require('../models/WithdrawalRequest');

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
    const items = await Transaction.find().sort({ created_at: -1 });
    res.json({ success: true, count: items.length, transactions: items });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

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
    w.status = 'REJECTED';
    w.approved_at = new Date();
    w.approved_by = req.admin._id;
    await w.save();
    res.json({ success: true, message: 'Withdrawal rejected' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;
