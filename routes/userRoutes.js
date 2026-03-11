const express = require('express');
const router = express.Router();
const mongoose = require('mongoose'); 
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Wallet = require('../models/Wallet');
const WithdrawalRequest = require('../models/WithdrawalRequest');
const { createPayoutForUser } = require('../services/razorpay');

// Helper function to get wallet 
async function getWalletByUserId(userId) { 
   let wallet = await Wallet.findOne({ userId }); 
   if (!wallet) { 
     wallet = await Wallet.findOne({ 
       userId: new mongoose.Types.ObjectId(userId) 
     }); 
   } 
   return wallet; 
 } 
 
 // Route 1 
 router.get('/wallet-balance/:userId', 
   async (req, res) => { 
   try { 
     const wallet = await getWalletByUserId( 
       req.params.userId 
     ); 
     console.log('Wallet balance:', wallet?.balance); 
     return res.json({ 
       success: true, 
       balance: Number(wallet?.balance || 0), 
       pendingWithdrawal: Number( 
         wallet?.pendingWithdrawal || 0 
       ), 
       transactions: wallet?.transactions || [] 
     }); 
   } catch (error) { 
     return res.status(500).json({ 
       success: false, 
       balance: 0 
     }); 
   } 
 }); 
 
 // Route 2 
 router.get('/wallet/details/:userId', 
   async (req, res) => { 
   try { 
     const wallet = await getWalletByUserId( 
       req.params.userId 
     ); 
     return res.json({ 
       success: true, 
       balance: Number(wallet?.balance || 0), 
       pendingWithdrawal: Number( 
         wallet?.pendingWithdrawal || 0 
       ), 
       transactions: wallet?.transactions || [] 
     }); 
   } catch (error) { 
     return res.status(500).json({ 
       success: false, 
       balance: 0 
     }); 
   } 
 }); 

// Phone verification removed. Email verification only.
// const otpStore = new Map(); // removed
// const { sendSms } = require('../services/sms'); // removed
const { sendEmail } = require('../services/email');

// /send-otp removed (email OTP is generated during registration)

router.post('/withdraw-money', async (req, res) => {
  try {
    const { userId, amount } = req.body;
    if (!userId || !amount || amount <= 0) {
      return res.status(400).json({ success: false, message: 'Valid userId and amount required' });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    let wallet = await Wallet.findOne({ userId });
    if (!wallet) wallet = new Wallet({ userId, role: user.role === 'taskProvider' ? 'provider' : 'user', balance: 0 });

    const walletBalance = wallet.balance;
    const minimumWithdrawal = walletBalance < 100 ? 1 : 10;

    if (amount < minimumWithdrawal) {
      return res.status(400).json({ 
        success: false, 
        message: `Minimum withdrawal is ₹${minimumWithdrawal}` 
      });
    }

    if (walletBalance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient wallet balance' });
    }

    // Create Withdrawal Request
    const withdrawal = new WithdrawalRequest({
      user_id: user._id,
      amount: amount,
      status: 'PENDING'
    });
    await withdrawal.save();

    // Call RazorpayX Payout API
    const payoutRes = await createPayoutForUser(user, amount);
    
    if (payoutRes.ok) {
      // Success: Deduct from wallet and update request
      wallet.balance -= amount;
      wallet.transactions.push({
        type: 'withdrawal',
        amount: amount,
        description: 'Withdrawal successful',
        status: 'completed',
        date: new Date()
      });
      await wallet.save();

      withdrawal.status = 'APPROVED';
      withdrawal.approved_at = new Date();
      await withdrawal.save();

      res.json({ success: true, message: 'Withdrawal successful', wallet: wallet.balance });
    } else {
      // If RazorpayX is not configured or fails, we still keep it as pending/failed
      // If it's just not configured (dev mode), we might want to simulate success
      if (payoutRes.reason === 'razorpayx_not_configured') {
        wallet.balance -= amount;
        wallet.transactions.push({
          type: 'withdrawal',
          amount: amount,
          description: 'Withdrawal successful (Dev Mode)',
          status: 'completed',
          date: new Date()
        });
        await wallet.save();

        withdrawal.status = 'APPROVED';
        withdrawal.approved_at = new Date();
        await withdrawal.save();

        return res.json({ success: true, message: 'Withdrawal successful (Dev Mode)', wallet: wallet.balance });
      }

      withdrawal.status = 'REJECTED';
      await withdrawal.save();
      res.status(400).json({ success: false, message: 'Payout failed', reason: payoutRes.reason, data: payoutRes.data });
    }
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to process withdrawal' });
  }
});

router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    if (!user.emailOtp || !user.emailOtpExpires) return res.status(400).json({ success: false, message: 'OTP not generated' });
    if (Date.now() > new Date(user.emailOtpExpires).getTime()) {
      user.emailOtp = undefined;
      user.emailOtpExpires = undefined;
      await user.save();
      return res.status(400).json({ success: false, message: 'OTP expired' });
    }
    if (String(otp) !== String(user.emailOtp)) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }
    user.isEmailVerified = true;
    user.emailOtp = undefined;
    user.emailOtpExpires = undefined;
    await user.save();
    return res.json({ success: true, message: 'Email verified' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to verify OTP' });
  }
});

// REGISTER
router.post('/register', async (req, res) => {
  try {
    const body = req.body || {};
    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const user = new User(Object.assign({}, body, {
      isEmailVerified: false,
      emailOtp: otp,
      emailOtpExpires: new Date(Date.now() + 5 * 60 * 1000)
    }));
    await user.save();
    let isMock = false;
    try {
      const r = await sendEmail(user.email, 'TaskNest Email Verification OTP', `Your OTP is: ${otp}`);
      isMock = !!(r && r.isMock);
    } catch (_) {}
    res.json({
      success: true,
      message: isMock ? 'Registration successful. (Mock Mode: Use Dev OTP)' : 'Registration successful. OTP sent to email.',
      userId: user._id,
      email: user.email,
      name: user.name,
      devOtp: isMock ? otp : undefined
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message || 'Registration failed',
      error: err.message 
    });
  }
});

// LOGIN
router.post('/login', async (req, res) => {
  try {
    const body = req.body || {};
    const email = body.email;
    const password = body.password;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password required' });
    }

    const user = await User.findOne({ email, password });

    if (!user) {
      return res.status(401).json({ 
        success: false,
        message: 'Invalid credentials' 
      });
    }
    if (user.status === 'BLOCKED') {
      return res.status(403).json({
        success: false,
        message: 'Account is blocked. Please contact support.'
      });
    }
    if (user.role !== 'admin' && !user.isEmailVerified) {
      return res.status(403).json({
        success: false,
        message: 'Please verify your email before login'
      });
    }

    res.json({
      success: true,
      message: 'Login successful',
      userId: user._id,
      email: user.email,
      name: user.name,
      role: user.role,
      wallet: user.wallet
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message || 'Login failed',
      error: err.message 
    });
  }
});

// ADD MONEY TO WALLET (simulated after UPI/Card - no real payment gateway)
// IMPORTANT: Must be defined BEFORE /:id route to avoid conflicts
router.post('/add-money', async (req, res) => {
  console.log('POST /users/add-money called', req.body);
  try {
    const { userId, amount } = req.body;
    if (!userId || amount == null || amount <= 0)
      return res.status(400).json({ success: false, message: 'Valid userId and amount (positive number) required' });

    const user = await User.findById(userId);
    if (!user)
      return res.status(404).json({ success: false, message: 'User not found' });

    const addAmount = Number(amount);
    user.wallet = (Number(user.wallet) || 0) + addAmount;
    await user.save();

    // Record transaction (CREDIT to user's wallet)
    try {
      await Transaction.create({
        user_id: user._id,
        amount: addAmount,
        type: 'CREDIT',
        status: 'SUCCESS'
      });
    } catch (txErr) {
      console.error('Failed to record add-money transaction', txErr);
      // do not fail the main request because of history-only error
    }

    console.log('Wallet updated:', user.wallet);
    res.json({
      success: true,
      message: 'Money added successfully',
      wallet: Number(user.wallet)
    });
  } catch (err) {
    console.error('Wallet add error:', err);
    res.status(400).json({ success: false, message: err.message || 'Failed to add money' });
  }
});

// GET ALL USERS (for testing/admin)
router.get('/all', async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.json({
      success: true,
      count: users.length,
      users: users
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// TRANSACTION HISTORY FOR USER (debits & credits)
router.get('/:id/transactions', async (req, res) => {
  try {
    const userId = req.params.id;
    const items = await Transaction
      .find({ user_id: userId })
      .sort({ created_at: -1 });
    res.json({
      success: true,
      count: items.length,
      transactions: items
    });
  } catch (err) {
    res.status(400).json({
      success: false,
      message: err.message || 'Failed to load transactions'
    });
  }
});

// GET USER BY ID
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: 'User not found' 
      });
    }
    res.json({
      success: true,
      user: user
    });
  } catch (err) {
    res.status(400).json({ 
      success: false,
      message: err.message 
    });
  }
});

// UPDATE PROFILE
router.put('/:id', async (req, res) => {
  try {
    const allowed = ['name','phone','location','bio','photo_url','skills'];
    const updates = {};
    allowed.forEach(k => {
      if (req.body[k] != null) updates[k] = req.body[k];
    });
    const user = await User.findByIdAndUpdate(req.params.id, updates, { new: true }).select('-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, user });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to update profile' });
  }
});

// CHANGE PASSWORD
router.post('/change-password', async (req, res) => {
  try {
    const { userId, currentPassword, newPassword } = req.body;
    if (!userId || !currentPassword || !newPassword) return res.status(400).json({ success: false, message: 'Missing fields' });
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    if (String(user.password) !== String(currentPassword)) return res.status(400).json({ success: false, message: 'Current password is incorrect' });
    user.password = String(newPassword);
    await user.save();
    res.json({ success: true, message: 'Password changed successfully' });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to change password' });
  }
});

// UPDATE NOTIFICATION PREFERENCES
router.post('/preferences', async (req, res) => {
  try {
    const { userId, preferences } = req.body;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    user.preferences = Object.assign({}, user.preferences || {}, {
      taskApproval: !!(preferences && preferences.taskApproval),
      taskRejection: !!(preferences && preferences.taskRejection),
      payment: !!(preferences && preferences.payment),
      taskUpdates: !!(preferences && preferences.taskUpdates),
    });
    await user.save();
    res.json({ success: true, preferences: user.preferences });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to update preferences' });
  }
});

router.post('/wallet', async (req, res) => {
  try {
    const { userId, accountHolderName, bankAccountNumber, ifsc, upiId } = req.body || {};
    if (!userId) return res.status(400).json({ success: false, message: 'userId required' });
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    user.bankDetails = Object.assign({}, user.bankDetails || {}, {
      accountHolderName: accountHolderName || (user.bankDetails && user.bankDetails.accountHolderName) || '',
      bankAccountNumber: bankAccountNumber || (user.bankDetails && user.bankDetails.bankAccountNumber) || '',
      ifsc: ifsc || (user.bankDetails && user.bankDetails.ifsc) || '',
      upiId: upiId || (user.bankDetails && user.bankDetails.upiId) || ''
    });
    await user.save();
    res.json({ success: true, bankDetails: user.bankDetails });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to update wallet details' });
  }
});

// UPDATE PRIVACY CONTROLS
router.post('/privacy', async (req, res) => {
  try {
    const { userId, isProfilePublic, showContactInfo } = req.body;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    user.privacy = Object.assign({}, user.privacy || {}, {
      isProfilePublic: isProfilePublic == null ? (user.privacy ? user.privacy.isProfilePublic : true) : !!isProfilePublic,
      showContactInfo: showContactInfo == null ? (user.privacy ? user.privacy.showContactInfo : true) : !!showContactInfo
    });
    await user.save();
    res.json({ success: true, privacy: user.privacy });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to update privacy' });
  }
});

// DEACTIVATE ACCOUNT
router.post('/deactivate', async (req, res) => {
  try {
    const { userId, confirm } = req.body;
    if (!confirm) return res.status(400).json({ success: false, message: 'Confirmation required' });
    const user = await User.findByIdAndUpdate(userId, { status: 'BLOCKED' }, { new: true }).select('-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, message: 'Account deactivated', user });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to deactivate account' });
  }
});

// SOFT DELETE ACCOUNT
router.post('/soft-delete', async (req, res) => {
  try {
    const { userId, confirm } = req.body;
    if (!confirm) return res.status(400).json({ success: false, message: 'Confirmation required' });
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    user.status = 'BLOCKED';
    user.deletedAt = new Date();
    await user.save();
    res.json({ success: true, message: 'Account soft deleted' });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message || 'Failed to soft delete account' });
  }
});
module.exports = router;
