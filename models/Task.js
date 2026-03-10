const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  category: { type: String, default: null },
  description: String,
  amount: {
    type: Number,
    required: true
  },
  skillset: { type: String }, // e.g., "Web Development", "Data Entry"
  workType: { type: String, enum: ['WFH', 'ONSITE', 'ALL'], default: 'ALL' },
  location: { type: String },
  duration: { type: String },
  postedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  acceptedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  approvedDate: { type: Date },
  taskDurationDays: { type: Number },
  submissionDeadline: { type: Date },
  finalFile: {
    filename: String,
    path: String,
    mime: String,
    size: Number,
    uploadedAt: { type: Date }
  },
  reviewRemark: { type: String },
  finalStatus: { type: String, enum: ['NONE','SUBMITTED','MISSED','APPROVED','REJECTED', 'PENDING_RELEASE'], default: 'NONE' },
  status: {
    type: String,
    enum: [
      'draft',
      'funded',
      'open',
      'assigned',
      'in_progress',
      'submitted',
      'reviewed',
      'pending_release',
      'completed',
      'disputed',
      'resolved',
      'expired',
      'cancelled'
    ],
    default: 'draft'
  },
  applications: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    state: { type: String, enum: ['APPLIED', 'ACCEPTED', 'REJECTED'], default: 'APPLIED' },
    createdAt: { type: Date, default: Date.now },
    sampleFile: {
      filename: String,
      path: String,
      mime: String,
      size: Number,
      uploadedAt: { type: Date, default: Date.now }
    }
  }],
  updates: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    text: { type: String },
    createdAt: { type: Date, default: Date.now }
  }]
}, { timestamps: true });

module.exports = mongoose.model('Task', taskSchema);

