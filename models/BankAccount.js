const mongoose = require('mongoose');

const bankAccountSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  role: { type: String, enum: ['provider', 'user'], required: true },
  accountHolderName: { type: String, required: true },
  accountNumber: { type: String, required: true }, // Should be encrypted in real apps
  ifscCode: { type: String, required: true },
  bankName: { type: String },
  branchName: { type: String },
  accountType: { type: String, enum: ['savings', 'current'], default: 'savings' },
  isVerified: { type: Boolean, default: false },
  isPrimary: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('BankAccount', bankAccountSchema);
