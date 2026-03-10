const mongoose = require('mongoose');

const withdrawalSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  userName: { type: String, required: true },
  amount: { type: Number, required: true },
  bankDetails: {
    accountHolderName: { type: String, required: true },
    accountNumber: { type: String, required: true },
    ifscCode: { type: String, required: true },
    bankName: { type: String, required: true },
    branchName: { type: String }
  },
  status: { type: String, enum: ['pending', 'processing', 'completed', 'rejected'], default: 'pending' },
  transactionReference: { type: String },
  requestedAt: { type: Date, default: Date.now },
  processedAt: { type: Date },
  completedAt: { type: Date },
  rejectedAt: { type: Date },
  rejectionReason: { type: String },
  processedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  remarks: { type: String }
});

module.exports = mongoose.model('Withdrawal', withdrawalSchema);
