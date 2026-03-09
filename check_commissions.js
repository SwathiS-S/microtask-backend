
const mongoose = require('mongoose');
require('dotenv').config();
const Transaction = require('./models/Transaction');

async function checkCommissions() {
  try {
    const uri = process.env.MONGODB_URI;
    await mongoose.connect(uri);
    console.log('Connected to MongoDB');
    
    const commissions = await Transaction.find({ type: 'COMMISSION' });
    if (commissions.length === 0) {
      console.log('No COMMISSION transactions found.');
    } else {
      console.log(`${commissions.length} COMMISSION transactions found:`);
      commissions.forEach(c => console.log(`- Amount: ₹${c.amount}, Date: ${c.created_at}, Status: ${c.status}`));
    }
    
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

checkCommissions();
