const express = require('express');
try { require('dotenv').config(); } catch (_) {}
const cors = require('cors');
const mongoose = require('mongoose');
const path = require('path');

const app = express();

// Security headers
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

// Import Routes
const userRoutes = require('./routes/userRoutes');
const bankRoutes = require('./routes/bankRoutes');
const walletRoutes = require('./routes/walletRoutes');
const escrowRoutes = require('./routes/escrowRoutes');
const adminRoutes = require('./routes/adminRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const taskRoutes = require('./routes/taskRoutes');

// API Routes
app.use('/api/users', userRoutes);
app.use('/api/bank', bankRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/admin/escrow', escrowRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/tasks', taskRoutes);

// Explicit Auth Endpoints (Redirect to userRoutes for consistency)
app.post('/api/auth/register', (req, res, next) => {
  req.url = '/register';
  userRoutes(req, res, next);
});
app.post('/api/auth/login', (req, res, next) => {
  req.url = '/login';
  userRoutes(req, res, next);
});

// ROOT ROUTE - Serve landing page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// HEALTH CHECK
app.get('/health', (req, res) => res.json({ status: 'OK', time: new Date() }));

// Error Handler for non-JSON responses
app.use((err, req, res, next) => {
  console.error('SERVER ERROR:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error'
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found` });
});

// Database Connection
const MONGODB_URI = process.env.MONGODB_URI;
const dbOptions = {
  bufferCommands: false,
  autoIndex: true,
};

mongoose.connect(MONGODB_URI || 'mongodb://127.0.0.1:27017/tasknest', dbOptions)
  .then(() => console.log('✅ MongoDB connected successfully'))
  .catch(err => console.error('❌ MongoDB connection error:', err.message));

const PORT = process.env.PORT || 5000;
const BASE_URL = process.env.BASE_URL || process.env.RENDER_EXTERNAL_URL || `http://localhost:${PORT}`;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on ${BASE_URL}`);
});
