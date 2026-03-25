const mongoose = require('mongoose'); 
const Escrow = require('./models/Escrow'); 
const Task = require('./models/Task');
const User = require('./models/User');
require('dotenv').config(); 

async function checkEscrowData() { 
  const uri = process.env.MONGO_URI || process.env.MONGODB_URI;
  await mongoose.connect(uri); 
  console.log('Connected to DB...'); 

  const escrows = await Escrow.find({ status: 'held' }) 
    .populate('userId', 'name email') 
    .populate('taskId', 'title acceptedBy assignedTo') 
    .lean(); 

  console.log('\n===== ESCROW RAW DATA ====='); 
  escrows.forEach((esc, i) => { 
    console.log(`\n--- Escrow ${i + 1} ---`); 
    console.log('ID:', esc._id); 
    console.log('taskTitle (snapshot):', esc.taskTitle); 
    console.log('taskId populated:', JSON.stringify(esc.taskId, null, 2)); 
    console.log('userId populated:', JSON.stringify(esc.userId, null, 2)); 
    console.log('status:', esc.status); 
  }); 

  console.log('\n===== DONE ====='); 
  mongoose.disconnect(); 
} 

checkEscrowData().catch(console.error); 
