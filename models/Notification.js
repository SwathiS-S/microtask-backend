const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  title: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: [
      'APPLICATION_RECEIVED',
      'APPLICATION_APPROVED',
      'APPLICATION_REJECTED',
      'UPDATE_SUBMITTED',
      'WORK_SUBMITTED',
      'WORK_APPROVED',
      'WORK_REJECTED',
      'PAYMENT_RELEASED',
      'PAYMENT_RECEIVED',
      'DISPUTE_RESOLVED',
      'ESCROW_RELEASE_REQUEST',
      'WITHDRAWAL_APPROVED',
      'WITHDRAWAL_REJECTED',
      'CHAT_MESSAGE',
      'TASK_CANCELLED',
      'TASK_COMPLETED'
    ],
    required: true
  },
  taskId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task'
  },
  isRead: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Auto-trigger FCM Push Notification
notificationSchema.post('save', async function (doc) {
  try {
    const User = mongoose.model('User');
    const user = await User.findById(doc.recipient);
    if (user && user.fcmToken) {
      const { sendPushNotification } = require('../utils/firebase');
      await sendPushNotification(user.fcmToken, doc.title, doc.message, {
        type: doc.type,
        notificationId: doc._id.toString(),
        taskId: doc.taskId ? doc.taskId.toString() : ''
      });
    }
  } catch (error) {
    console.error('Error in notification post-save hook:', error);
  }
});

module.exports = mongoose.model('Notification', notificationSchema);
