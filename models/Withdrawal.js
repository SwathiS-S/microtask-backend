const mongoose = require('mongoose');

const withdrawalSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  bankAccountId: { type: mongoose.Schema.Types.ObjectId, ref: 'BankAccount', required: true },
  status: { type: String, enum: ['pending', 'processing', 'completed', 'failed'], default: 'pending' },
  requestedAt: { type: Date, default: Date.now },
  completedAt: { type: Date },
  remarks: { type: String }
});

module.exports = mongoose.model('Withdrawal', withdrawalSchema);
