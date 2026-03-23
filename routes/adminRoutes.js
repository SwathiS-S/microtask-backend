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
const Payout = require('../models/Payout');

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

// --- USER MANAGEMENT ---

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

// --- TASK MANAGEMENT ---

router.get('/tasks', async (req, res) => { 
   try { 
     const tasks = await Task.find({}) 
       .populate('postedBy', 'name email') 
       .populate('acceptedBy', 'name email') 
       .select('title amount status postedBy acceptedBy createdAt');
     res.json({ success: true, count: tasks.length, tasks }); 
   } catch (e) { 
     res.status(500).json({ success: false, message: e.message }); 
   } 
 }); 

router.delete('/tasks/:id', async (req, res) => {
  try {
    const t = await Task.findById(req.params.id);
    if (!t) return res.status(404).json({ success: false, message: 'Task not found' });
    await Task.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Task deleted' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// --- WITHDRAWAL MANAGEMENT (Consolidated) ---

router.get('/withdrawals', async (req, res) => { 
   try { 
     const withdrawals = await Withdrawal.find({}) 
       .populate('userId', 'name email') 
       .sort({ requestedAt: -1 }); 
     res.json({ success: true, count: withdrawals.length, withdrawals }); 
   } catch(e) { 
     res.status(500).json({ success: false, message: e.message }); 
   } 
 }); 
 
 router.post('/withdrawals/:id/approve', async (req, res) => { 
   try { 
     const withdrawal = await Withdrawal.findByIdAndUpdate( 
       req.params.id, 
       { status: 'completed', processedAt: new Date(), processedBy: req.admin._id }, 
       { new: true } 
     ); 
     if (!withdrawal) return res.status(404).json({ success: false, message: 'Withdrawal not found' });

     // Update wallet pendingWithdrawal 
     await Wallet.findOneAndUpdate( 
       { userId: withdrawal.userId }, 
       { $inc: { pendingWithdrawal: -withdrawal.amount } } 
     ); 

     // Notify User
     await Notification.create({
       recipient: withdrawal.userId,
       title: '✅ Withdrawal Approved',
       message: `Your withdrawal of ₹${withdrawal.amount} has been approved and processed.`,
       type: 'WITHDRAWAL_APPROVED'
     });

     res.json({ success: true, message: 'Withdrawal approved!' }); 
   } catch(e) { 
     res.status(500).json({ success: false, message: e.message }); 
   } 
 }); 
 
 router.post('/withdrawals/:id/reject', async (req, res) => { 
   try { 
     const { reason } = req.body || {};
     const withdrawal = await Withdrawal.findByIdAndUpdate( 
       req.params.id, 
       { status: 'rejected', rejectedAt: new Date(), processedBy: req.admin._id, rejectionReason: reason || 'Not specified' }, 
       { new: true } 
     ); 
     if (!withdrawal) return res.status(404).json({ success: false, message: 'Withdrawal not found' });

     // Refund balance back to wallet 
     await Wallet.findOneAndUpdate( 
       { userId: withdrawal.userId }, 
       { 
         $inc: { 
           balance: +withdrawal.amount, 
           pendingWithdrawal: -withdrawal.amount 
         }, 
         $push: { 
           transactions: { 
             transactionType: 'refund', 
             amount: withdrawal.amount, 
             description: 'Withdrawal rejected - amount refunded', 
             status: 'completed', 
             date: new Date() 
           } 
         } 
       } 
     ); 
     
     // Update User model wallet for backward compatibility
     await User.findByIdAndUpdate(withdrawal.userId, { $inc: { wallet: +withdrawal.amount } });

     // Notify User
     await Notification.create({
       recipient: withdrawal.userId,
       title: '❌ Withdrawal Rejected',
       message: `Your withdrawal of ₹${withdrawal.amount} was rejected. Funds refunded. Reason: ${reason || 'Not specified'}`,
       type: 'WITHDRAWAL_REJECTED'
     });

     res.json({ success: true, message: 'Withdrawal rejected and refunded!' }); 
   } catch(e) { 
     res.status(500).json({ success: false, message: e.message }); 
   } 
 }); 

// --- FINANCIAL ANALYTICS ---

 router.get('/revenue', async (req, res) => { 
   try { 
     const wallets = await Wallet.find({}); 
     let inflow = 0, outflow = 0, commission = 0, pendingWithdrawals = 0; 
     
     wallets.forEach(wallet => { 
       wallet.transactions.forEach(tx => { 
         const type = (tx.transactionType || '').toLowerCase(); 
         if (type === 'escrow_hold') inflow += Number(tx.amount || 0); 
         if (type === 'credit') outflow += Number(tx.amount || 0); 
         if (type === 'commission') commission += Number(tx.amount || 0); 
         if (type === 'withdrawal') pendingWithdrawals += Number(tx.amount || 0); 
       }); 
     }); 
     
     res.json({ 
       success: true, 
       totalInflow: inflow.toFixed(2), 
       totalOutflow: outflow.toFixed(2), 
       netCommission: commission.toFixed(2), 
       pendingWithdrawals: pendingWithdrawals.toFixed(2), 
       netRevenue: (inflow - outflow).toFixed(2) 
     }); 
   } catch(e) { 
     res.status(500).json({ success: false, message: e.message }); 
   } 
 }); 

router.get('/wallet-transactions', async (req, res) => {
  try {
    const wallets = await Wallet.find({})
      .populate({ path: 'userId', model: 'User', select: 'name email role' });
    
    let allTransactions = [];
    wallets.forEach(wallet => {
      if (wallet.transactions && Array.isArray(wallet.transactions)) {
        wallet.transactions.forEach(tx => {
          allTransactions.push({
            ...tx.toObject(),
            userName: wallet.userId?.name || wallet.userId?.email || ('User-' + wallet.userId),
            userEmail: wallet.userId?.email || '',
            walletRole: wallet.role
          });
        });
      }
    });
    
    allTransactions.sort((a, b) => new Date(b.date || b.created_at) - new Date(a.date || a.created_at));
    
    res.json({ success: true, transactions: allTransactions });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// --- DASHBOARD SUMMARY ---

router.get('/dashboard-summary', async (req, res) => {
  try {
    const users = await User.countDocuments({});
    const tasks = await Task.countDocuments({});
    const pendingWithdrawals = await Withdrawal.countDocuments({ status: 'pending' });
    const pendingEscrows = await Escrow.countDocuments({ status: 'held' });

    res.json({
      success: true,
      stats: {
        users,
        tasks,
        pendingWithdrawals,
        pendingEscrows
      }
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// --- ADMIN SELF-WALLET MANAGEMENT ---

router.get('/wallet', async (req, res) => {
  try {
    const adminId = req.admin._id;
    const wallet = await Wallet.findOne({ userId: adminId });
    const admin = await User.findById(adminId).select('bankDetails');
    const withdrawals = await Withdrawal.find({ userId: adminId }).sort({ requestedAt: -1 });

    res.json({
      success: true,
      wallet: wallet ? wallet.balance : 0,
      bankDetails: admin.bankDetails || null,
      withdrawals: withdrawals || []
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.post('/bank-details', async (req, res) => {
  try {
    const adminId = req.admin._id;
    const { bankDetails } = req.body;
    
    if (!bankDetails || !bankDetails.accountNumber) {
      return res.status(400).json({ success: false, message: 'Invalid bank details' });
    }

    await User.findByIdAndUpdate(adminId, { bankDetails });
    res.json({ success: true, message: 'Bank details updated' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.post('/withdraw', async (req, res) => {
  try {
    const adminId = req.admin._id;
    const { amount } = req.body;
    
    const wallet = await Wallet.findOne({ userId: adminId });
    if (!wallet || wallet.balance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient commission balance' });
    }

    const admin = await User.findById(adminId);
    if (!admin.bankDetails || !admin.bankDetails.accountNumber) {
      return res.status(400).json({ success: false, message: 'Please add bank details first' });
    }

    // Create withdrawal request
    const withdrawal = await Withdrawal.create({
      userId: adminId,
      amount,
      bankDetails: admin.bankDetails,
      status: 'pending',
      requestedAt: new Date()
    });

    // Deduct from wallet
    wallet.balance -= amount;
    wallet.transactions.push({
      amount,
      transactionType: 'withdrawal',
      description: `Commission withdrawal request #${withdrawal._id.toString().substring(0, 8)}`,
      date: new Date()
    });
    await wallet.save();

    // Update User model wallet for backward compatibility
    admin.wallet = wallet.balance;
    await admin.save();

    res.json({ success: true, message: 'Withdrawal request submitted successfully', withdrawal });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;
