const mongoose = require('mongoose');

const escrowSchema = new mongoose.Schema({
  taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },
  providerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, 
   amount: { type: Number, required: true }, 
   workerAmount: { type: Number, default: 0 }, // ✅ ADD THIS 
   platformFee: { type: Number, default: 0 }, 
   totalPaid: { type: Number, required: true }, 
  status: { type: String, enum: ['held', 'released', 'refunded', 'disputed'], default: 'held' },
  heldAt: { type: Date, default: Date.now },
  releasedAt: { type: Date },
  refundedAt: { type: Date },
  reason: { type: String }
});

module.exports = mongoose.model('Escrow', escrowSchema);
