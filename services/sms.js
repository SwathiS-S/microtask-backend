const twilio = require('twilio');

function normalizePhone(raw, defaultCountryCode) {
  const digits = String(raw).replace(/\D/g, '');
  if (!digits) return null;
  if (raw.startsWith('+')) return `+${digits}`;
  if (defaultCountryCode && !defaultCountryCode.startsWith('+')) {
    defaultCountryCode = `+${defaultCountryCode}`;
  }
  if (defaultCountryCode) return `${defaultCountryCode}${digits}`;
  return `+${digits}`;
}

async function sendSms(toRaw, body) {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_FROM_NUMBER;
  const cc = process.env.COUNTRY_CODE || '';
  const to = normalizePhone(toRaw, cc);
  if (!sid || !token || !from) return { ok: false, reason: 'twilio_not_configured' };
  try {
    const client = twilio(sid, token);
    await client.messages.create({ to, from, body });
    return { ok: true };
  } catch (err) {
    return { ok: false, reason: err.message || 'twilio_error' };
  }
}

module.exports = { sendSms, normalizePhone };
