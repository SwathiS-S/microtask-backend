const express = require('express');
try { require('dotenv').config(); } catch (_) {}
const cors = require('cors');
const http = require('http');
const fs = require('fs');
const app = express();
const path = require('path');

// Security headers (Removed HSTS for HTTP)
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  next();
});

app.use(express.static(path.join(__dirname, 'public')));

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ROOT ROUTE - Serve landing page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// SIMPLE OTP ALIAS ROUTES (email-only)
const { sendEmail } = require('./services/email');
app.post('/auth/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body || {};
    const User = require('./models/User');
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
    res.json({ success: true, message: 'Email verified' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to verify OTP' });
  }
});

// IMPORT ROUTES
const userRoutes = require('./routes/userRoutes');
const bankRoutes = require('./routes/bankRoutes');
const walletRoutes = require('./routes/walletRoutes');
const escrowRoutes = require('./routes/escrowRoutes');

app.use('/users', userRoutes);
app.use('/bank', bankRoutes);
app.use('/wallet', walletRoutes);
app.use('/escrow', escrowRoutes);
app.use('/', escrowRoutes);
// Explicit auth endpoints to avoid path conflicts with /users/:id
const User = require('./models/User');
app.post('/auth/register', async (req, res) => {
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
app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const user = await User.findOne({ email, password });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    if (user.status === 'BLOCKED') {
      return res.status(403).json({ success: false, message: 'Account is blocked. Please contact support.' });
    }
    if (user.role !== 'admin' && !user.isEmailVerified) {
      return res.status(403).json({ success: false, message: 'Please verify your email before login' });
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
    res.status(400).json({ success: false, message: err.message || 'Login failed', error: err.message });
  }
});
const taskRoutes = require('./routes/taskRoutes');
app.use('/tasks', taskRoutes);
const adminRoutes = require('./routes/adminRoutes');
app.use('/admin', adminRoutes);
const paymentRoutes = require('./routes/paymentRoutes');
app.use('/payments', paymentRoutes);
const notificationRoutes = require('./routes/notificationRoutes');
app.use('/notifications', notificationRoutes);
// AUTO DEADLINE CHECK (Run Daily)
const Escrow = require('./models/Escrow');
const Wallet = require('./models/Wallet');
const Task = require('./models/Task');

async function checkDeadlines() {
  try {
    const now = new Date();
    // Find tasks that are expired and funded but no user assigned
    const expiredTasks = await Task.find({
      status: 'funded',
      deadline: { $lt: now },
      acceptedBy: { $exists: false }
    });

    for (const task of expiredTasks) {
      const escrow = await Escrow.findOne({ taskId: task._id, status: 'held' });
      if (escrow) {
        // Refund escrow to provider
        escrow.status = 'refunded';
        escrow.refundedAt = now;
        await escrow.save();

        const wallet = await Wallet.findOne({ userId: escrow.providerId });
        if (wallet) {
          wallet.escrowBalance -= escrow.amount;
          wallet.balance += escrow.amount;
          wallet.transactions.push({
            type: 'refund',
            amount: escrow.amount,
            taskId: task._id,
            description: 'Auto-refund due to deadline expiry',
            status: 'completed'
          });
          await wallet.save();
        }

        task.status = 'expired';
        await task.save();
        console.log(`Task ${task._id} auto-refunded and marked as expired.`);
      }
    }
  } catch (err) {
    console.error('Error in checkDeadlines:', err.message);
  }
}

// Run every 24 hours
setInterval(checkDeadlines, 24 * 60 * 60 * 1000);

// Force redeploy
const PORT = process.env.PORT || 5000;
const BASE_URL = process.env.BASE_URL || `http://localhost:${PORT}`;
const mongoose = require('mongoose');

// Mongoose connection options
const dbOptions = {
  bufferCommands: false, // Fail fast if not connected
  autoIndex: true,
};

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.warn('\n⚠️  WARNING: MONGODB_URI is not defined in environment variables!');
  console.warn('Backend will attempt to connect to local MongoDB at mongodb://127.0.0.1:27017/tasknest');
  console.warn('If you are running on Render, this WILL fail. Please add MONGODB_URI to your Render Environment Variables.\n');
}

mongoose.connect(MONGODB_URI || 'mongodb://127.0.0.1:27017/tasknest', dbOptions)
  .then(() => console.log('✅ MongoDB connected successfully'))
  .catch(err => {
    console.error('❌ MongoDB connection error:', err.message);
    if (err.message.includes('buffering timed out')) {
      console.error('Hint: Mongoose could not connect to the database. Check your MONGODB_URI.');
    }
  });

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on ${BASE_URL}`);
});
