const Razorpay = require('razorpay');
const crypto = require('crypto');

function getClient() {
  const key_id = process.env.RAZORPAY_KEY_ID;
  const key_secret = process.env.RAZORPAY_KEY_SECRET;
  if (!key_id || !key_secret) return null;
  return new Razorpay({ key_id, key_secret });
}

async function createOrder(amount, receipt) {
  const client = getClient();
  if (!client) return { ok: false, reason: 'razorpay_not_configured' };
  try {
    const order = await client.orders.create({
      amount: Math.round(Number(amount) * 100), // in paise
      currency: 'INR',
      receipt: receipt || `receipt_${Date.now()}`
    });
    return { ok: true, data: order };
  } catch (err) {
    return { ok: false, reason: 'order_failed', error: err };
  }
}

function verifySignature(order_id, payment_id, signature) {
  const secret = process.env.RAZORPAY_KEY_SECRET;
  if (!secret) return false;
  const generated_signature = crypto
    .createHmac('sha256', secret)
    .update(order_id + '|' + payment_id)
    .digest('hex');
  return generated_signature === signature;
}

async function requestX(path, body) {
  const fetchLib = global.fetch || require('node-fetch');
  const key = process.env.RAZORPAY_KEY_ID;
  const secret = process.env.RAZORPAY_KEY_SECRET;
  if (!key || !secret) return { ok: false, reason: 'razorpayx_not_configured' };
  const auth = Buffer.from(`${key}:${secret}`).toString('base64');
  const res = await fetchLib(`https://api.razorpay.com/v1/${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Basic ${auth}` },
    body: JSON.stringify(body || {})
  });
  const text = await res.text();
  let data = null;
  try { data = JSON.parse(text); } catch (_) { data = { raw: text }; }
  return res.ok ? { ok: true, data } : { ok: false, data };
}

async function createContact(name, email) {
  return requestX('contacts', { name, email });
}

async function createFundAccount(contact_id, bankDetails) {
  if (bankDetails && bankDetails.upiId) {
    return requestX('fund_accounts', {
      contact_id,
      account_type: 'vpa',
      vpa: { address: bankDetails.upiId }
    });
  }
  return requestX('fund_accounts', {
    contact_id,
    account_type: 'bank_account',
    bank_account: {
      name: bankDetails.accountHolderName,
      ifsc: bankDetails.ifsc,
      account_number: bankDetails.bankAccountNumber
    }
  });
}

async function createPayout(fund_account_id, amount, currency, purpose) {
  return requestX('payouts', {
    account_number: process.env.RAZORPAYX_SOURCE || 'XXXXXXXXXXXX',
    fund_account_id,
    amount: Math.round(Number(amount) * 100),
    currency: currency || 'INR',
    mode: 'IMPS',
    purpose: purpose || 'payout'
  });
}

async function createPayoutForUser(user, amount) {
  const contact = await createContact(user.name || user.email || 'User', user.email || '');
  if (!contact.ok) return { ok: false, reason: 'contact_failed', data: contact.data };
  const fund = await createFundAccount(contact.data.id || contact.data.entity && contact.data.entity.id, user.bankDetails || {});
  if (!fund.ok) return { ok: false, reason: 'fund_failed', data: fund.data };
  const payout = await createPayout(fund.data.id || fund.data.entity && fund.data.entity.id, amount, 'INR', 'task_payout');
  if (!payout.ok) return { ok: false, reason: 'payout_failed', data: payout.data };
  return { ok: true, data: payout.data };
}

module.exports = { getClient, createOrder, verifySignature, createPayoutForUser };
