const mongoose = require('mongoose');

const payoutSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  task_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Task' },
  amount: { type: Number, required: true },
  method: { type: String, enum: ['BANK','UPI'], required: true },
  payout_id: { type: String },
  status: { type: String, enum: ['PENDING','SUCCESS','FAILED','DEV_MODE'], default: 'PENDING' },
  created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Payout', payoutSchema);
