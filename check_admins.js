
const mongoose = require('mongoose');
require('dotenv').config();

const UserSchema = new mongoose.Schema({
  email: String,
  role: String,
  status: String,
  isEmailVerified: Boolean
});

const User = mongoose.model('User', UserSchema);

async function checkAdmins() {
  try {
    const uri = process.env.MONGODB_URI;
    if (!uri) {
      console.error('MONGODB_URI not found in .env');
      process.exit(1);
    }
    await mongoose.connect(uri);
    console.log('Connected to MongoDB');
    
    const admins = await User.find({ role: 'admin' });
    if (admins.length === 0) {
      console.log('No admin users found in database.');
      const allUsers = await User.find({});
      console.log(`Total users in DB: ${allUsers.length}`);
      allUsers.forEach(u => console.log(`- ${u.email} (Role: ${u.role})`));
    } else {
      console.log('Admin users found:');
      admins.forEach(u => console.log(`- ${u.email} (Status: ${u.status}, Verified: ${u.isEmailVerified})`));
    }
    
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

checkAdmins();
