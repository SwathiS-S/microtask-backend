const sendEmail = async (to, subject, body) => {
  const BASE_URL = process.env.BASE_URL || 'http://localhost:5000';
  console.log(`Sending email to ${to} with subject "${subject}"`);
  console.log(`Email Body: ${body}`);
  // If you need to include a verification link:
  // const verificationLink = `${BASE_URL}/auth/verify?email=${to}`;
  
  return { ok: true, devMode: true };
};

module.exports = { sendEmail };
