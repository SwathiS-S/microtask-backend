const mongoose = require('mongoose');

const withdrawalRequestSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  status: { type: String, enum: ['PENDING', 'APPROVED', 'REJECTED'], default: 'PENDING' },
  created_at: { type: Date, default: Date.now },
  approved_at: { type: Date },
  approved_by: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
});

module.exports = mongoose.model('WithdrawalRequest', withdrawalRequestSchema);
