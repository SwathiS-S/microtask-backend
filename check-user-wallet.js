const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');
const Wallet = require('./models/Wallet');

async function check() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to DB');
    
    const user = await User.findOne({ email: 'swathis225@gmail.com' });
    if (!user) {
      console.log('User not found: swathis225@gmail.com');
      return;
    }
    console.log('User found:', user._id, user.email, user.role);
    
    const wallet = await Wallet.findOne({ userId: user._id });
    if (!wallet) {
      console.log('Wallet not found for userId:', user._id);
    } else {
      console.log('Wallet found:', wallet._id);
      console.log('Balance:', wallet.balance);
      console.log('Transactions count:', wallet.transactions.length);
      console.log('Transactions:', JSON.stringify(wallet.transactions, null, 2));
    }
    
    await mongoose.disconnect();
  } catch (err) {
    console.error(err);
  }
}
check();
