const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  wallet_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet' },
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  task_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Task' },
  amount: { type: Number, required: true },
  type: { type: String, enum: ['CREDIT','DEBIT','COMMISSION'], required: true },
  status: { type: String, enum: ['PENDING','SUCCESS','FAILED'], default: 'PENDING' },
  created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Transaction', transactionSchema);
