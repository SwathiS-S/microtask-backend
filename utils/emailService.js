const nodemailer = require('nodemailer'); 
 
const transporter = nodemailer.createTransport({ 
  service: 'gmail', 
  auth: { 
    user: process.env.EMAIL_USER, 
    pass: process.env.EMAIL_PASS 
  } 
}); 
 
const sendOTPEmail = async (toEmail, otp, name) => { 
  const mailOptions = { 
    from: `"TaskNest" <${process.env.EMAIL_USER}>`, 
    to: toEmail,  // ← sends to THE USER'S email 
    subject: 'Verify your TaskNest account', 
    html: ` 
      <div style="font-family:Arial,sans-serif; max-width:480px; margin:0 auto; padding:32px; background:#FAF8F3; border-radius:12px;"> 
        <div style="text-align:center; margin-bottom:24px;"> 
          <h1 style="color:#1E3A5F; font-size:28px; margin:0;">Task<span style="color:#C9A84C;">Nest</span></h1> 
        </div> 
        <div style="background:white; border-radius:10px; padding:28px; border:1px solid #e2e8f0;"> 
          <h2 style="color:#1E3A5F; font-size:20px; margin:0 0 12px;">Verify your email</h2> 
          <p style="color:#5a6a7a; font-size:14px; margin:0 0 24px;"> 
            Hi <strong>${name || 'there'}</strong>, enter this OTP to complete your registration: 
          </p> 
          <div style="background:#1E3A5F; border-radius:10px; padding:20px; text-align:center; margin-bottom:24px;"> 
            <div style="font-size:40px; font-weight:800; color:#C9A84C; letter-spacing:12px;">${otp}</div> 
          </div> 
          <p style="color:#5a6a7a; font-size:13px; margin:0;"> 
            This OTP expires in <strong>10 minutes</strong>.<br> 
            Do not share it with anyone. 
          </p> 
        </div> 
        <p style="color:#aaa; font-size:11px; text-align:center; margin-top:20px;"> 
          © 2026 TaskNest · teamtasknest@gmail.com 
        </p> 
      </div> 
    ` 
  }; 
  await transporter.sendMail(mailOptions); 
}; 
 
module.exports = { sendOTPEmail }; 
