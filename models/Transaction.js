const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  wallet_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet' },
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  task_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Task' },
  taskTitle: { type: String },
  amount: { type: Number, required: true },
  type: { 
    type: String, 
    enum: ['credit', 'debit', 'escrow_hold', 'escrow_release', 'refund', 'withdrawal', 'COMMISSION'], 
    required: true 
  },
  status: { type: String, enum: ['pending', 'completed', 'failed', 'SUCCESS'], default: 'pending' },
  description: { type: String },
  created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Transaction', transactionSchema);
