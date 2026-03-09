
const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');

async function createAdmin() {
  try {
    const uri = process.env.MONGODB_URI;
    if (!uri) {
      console.error('MONGODB_URI not found in .env');
      process.exit(1);
    }
    await mongoose.connect(uri);
    console.log('Connected to MongoDB');
    
    const email = 'admin@example.com';
    const password = 'adminpassword';
    
    let admin = await User.findOne({ email });
    if (admin) {
      console.log(`Admin user with email ${email} already exists.`);
      admin.role = 'admin';
      admin.isEmailVerified = true;
      admin.password = password;
      await admin.save();
      console.log(`Updated existing user to admin with password: ${password}`);
    } else {
      admin = new User({
        name: 'TaskNest Admin',
        email: email,
        password: password,
        role: 'admin',
        isEmailVerified: true,
        status: 'ACTIVE'
      });
      await admin.save();
      console.log(`Created new admin user with email ${email} and password: ${password}`);
    }
    
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

createAdmin();
