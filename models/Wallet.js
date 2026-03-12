const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  role: { type: String, enum: ['provider', 'user'], required: true },
  balance: { type: Number, default: 0 },
  escrowBalance: { type: Number, default: 0 },
  pendingWithdrawal: { type: Number, default: 0 },
  transactions: [
    {
      transactionType: { 
        type: String, 
        enum: ['credit', 'debit', 'escrow_hold', 'escrow_release', 'refund', 'withdrawal'], 
        required: true 
      },
      amount: { type: Number, required: true },
      taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task' },
      taskTitle: { type: String },
      description: { type: String },
      status: { type: String, enum: ['pending', 'completed', 'failed'], default: 'pending' },
      date: { type: Date, default: Date.now }
    }
  ],
  updated_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Wallet', walletSchema);
