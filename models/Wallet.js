const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  balance: { type: Number, default: 0 },
  updated_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Wallet', walletSchema);
