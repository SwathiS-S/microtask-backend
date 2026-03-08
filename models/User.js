const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String },
  location: { type: String },
  role: { type: String, enum: ['taskUser', 'taskProvider', 'admin'], default: 'taskUser' },
  status: { type: String, enum: ['ACTIVE', 'BLOCKED'], default: 'ACTIVE' },
  phoneVerified: { type: Boolean, default: false },
  isEmailVerified: { type: Boolean, default: false },
  emailOtp: { type: String },
  emailOtpExpires: { type: Date },
  bio: { type: String },
  photo_url: { type: String },
  skills: [{ type: String }],
  preferences: {
    taskApproval: { type: Boolean, default: true },
    taskRejection: { type: Boolean, default: true },
    payment: { type: Boolean, default: true },
    taskUpdates: { type: Boolean, default: true }
  },
  privacy: {
    isProfilePublic: { type: Boolean, default: true },
    showContactInfo: { type: Boolean, default: true }
  },
  bankDetails: {
    accountHolderName: { type: String },
    bankAccountNumber: { type: String },
    ifsc: { type: String },
    upiId: { type: String }
  },
  wallet: { type: Number, default: 0 },
  deletedAt: { type: Date },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);
