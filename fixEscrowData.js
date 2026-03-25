const mongoose = require('mongoose'); 
const Escrow = require('./models/Escrow'); 
const Task = require('./models/Task'); 
const User = require('./models/User'); // Import User to register the schema
require('dotenv').config(); 

async function fixEscrowData() { 
  // Handle both MONGO_URI and MONGODB_URI from .env
  const uri = process.env.MONGO_URI || process.env.MONGODB_URI;
  if (!uri) {
    console.error('Error: MONGO_URI or MONGODB_URI not found in .env');
    return;
  }

  await mongoose.connect(uri); 
  console.log('Connected to DB...'); 

  // Find all held escrows with missing userId or taskTitle 
  const escrows = await Escrow.find({ 
    status: 'held', 
    $or: [ 
      { userId: { $exists: false } },
      { userId: null }, 
      { taskTitle: { $exists: false } },
      { taskTitle: null }, 
      { taskTitle: '' } 
    ] 
  }); 

  console.log(`Found ${escrows.length} escrows to potentially fix...`); 

  for (const escrow of escrows) { 
    try {
      const task = await Task.findById(escrow.taskId) 
        .populate('acceptedBy', 'name email'); 

      if (task) { 
        let updated = false;

        // Fix taskTitle 
        if (!escrow.taskTitle) { 
          escrow.taskTitle = task.title; 
          updated = true;
        } 

        // Fix userId (worker) 
        if (!escrow.userId) { 
          const worker = task.acceptedBy; 
          if (worker) { 
            escrow.userId = worker._id || worker; 
            updated = true;
          } 
        } 

        // Fix missing totalPaid if necessary
        if (escrow.totalPaid === undefined || escrow.totalPaid === null) {
          escrow.totalPaid = escrow.amount || 0;
          updated = true;
        }

        if (updated) {
          // Use validateBeforeSave: false to bypass schema validation for older records if needed,
          // but here we are trying to fix the validation issue by providing totalPaid.
          await escrow.save(); 
          console.log(`✅ Fixed escrow ${escrow._id} — Task: ${escrow.taskTitle}, Worker: ${escrow.userId}`); 
        } else {
          console.log(`ℹ️ Escrow ${escrow._id} — No updates needed (already has info or no worker assigned)`);
        }
      } else { 
        // Task deleted but we can still fix totalPaid if it's missing
        if (escrow.totalPaid === undefined || escrow.totalPaid === null) {
          escrow.totalPaid = escrow.amount || 0;
          await escrow.save();
          console.log(`✅ Fixed missing totalPaid for deleted task escrow ${escrow._id}`);
        } else {
          console.log(`⚠️ Escrow ${escrow._id} — Task not found (deleted)`); 
        }
      } 
    } catch (err) {
      console.error(`❌ Error processing escrow ${escrow._id}:`, err.message);
    }
  } 

  console.log('Migration complete!'); 
  mongoose.disconnect(); 
} 

fixEscrowData().catch(console.error); 
