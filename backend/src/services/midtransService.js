const crypto = require('crypto');

const MIDTRANS_SERVER_KEY = String(process.env.MIDTRANS_SERVER_KEY || '').trim();
const MIDTRANS_CLIENT_KEY = String(process.env.MIDTRANS_CLIENT_KEY || '').trim();
const IS_PRODUCTION = String(process.env.MIDTRANS_IS_PRODUCTION || 'false').toLowerCase() === 'true';

const BASE_URL = IS_PRODUCTION
  ? 'https://api.midtrans.com'
  : 'https://api.sandbox.midtrans.com';

function isConfigured() {
  return (
    MIDTRANS_SERVER_KEY.length > 0 &&
    !MIDTRANS_SERVER_KEY.includes('YOUR_SANDBOX_SERVER_KEY') &&
    !MIDTRANS_SERVER_KEY.includes('YOUR_SERVER_KEY')
  );
}

function getAuthHeader() {
  const token = Buffer.from(`${MIDTRANS_SERVER_KEY}:`).toString('base64');
  return `Basic ${token}`;
}

/**
 * Buat transaksi QRIS melalui Midtrans Core API
 */
async function createQrisTransaction({
  purchaseId,
  grossAmount,
  buyerName,
  buyerPhone,
  propertyTitle,
}) {
  const orderId = `ASTANA-${purchaseId}-${Date.now()}`;
  const amount = Math.max(1, Math.round(Number(grossAmount) || 0));

  if (!isConfigured()) {
    throw new Error(
      'Midtrans Sandbox belum dikonfigurasi. Isi MIDTRANS_SERVER_KEY di backend/.env.',
    );
  }

  try {
    const payload = {
      payment_type: 'qris',
      transaction_details: {
        order_id: orderId,
        gross_amount: amount,
      },
      customer_details: {
        first_name: String(buyerName || 'Pembeli').substring(0, 50),
        phone: buyerPhone ? String(buyerPhone).substring(0, 20) : undefined,
      },
      item_details: [
        {
          id: `PROP-${purchaseId}`,
          price: amount,
          quantity: 1,
          name: String(propertyTitle || 'Pemesanan Properti').substring(0, 50),
        },
      ],
      qris: {
        acquirer: 'gopay',
      },
    };

    const response = await fetch(`${BASE_URL}/v2/charge`, {
      method: 'POST',
      headers: {
        Authorization: getAuthHeader(),
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json();

    if (!response.ok || (data.status_code && !data.status_code.startsWith('2'))) {
      console.error('[Midtrans Error]', data);
      throw new Error(data.status_message || 'Gagal membuat QRIS di Midtrans');
    }

    // Ambil QR URL dari array actions
    let qrUrl = null;
    if (Array.isArray(data.actions)) {
      const qrAction = data.actions.find(
        (a) => a.name === 'generate-qr-code' || a.name === 'qr-code',
      );
      if (qrAction) {
        qrUrl = qrAction.url;
      }
    }

    const expiryTime = data.expiry_time || new Date(Date.now() + 15 * 60 * 1000).toISOString().slice(0, 19).replace('T', ' ');

    if (!qrUrl) {
      throw new Error('Midtrans tidak mengembalikan URL QRIS pada respons charge');
    }

    return {
      orderId: data.order_id || orderId,
      transactionId: data.transaction_id || `TX-${Date.now()}`,
      qrUrl: qrUrl || '',
      paymentStatus: data.transaction_status || 'pending',
      expiryTime,
      isMock: false,
    };
  } catch (error) {
    console.error('[Midtrans API Exception]', error.message);
    throw error;
  }
}

/**
 * Cek status transaksi ke Midtrans Core API
 */
async function checkTransactionStatus(orderId) {
  if (!orderId) {
    return { status: 'unknown' };
  }

  if (!isConfigured()) {
    throw new Error(
      'Midtrans Sandbox belum dikonfigurasi. Isi MIDTRANS_SERVER_KEY di backend/.env.',
    );
  }

  try {
    const response = await fetch(`${BASE_URL}/v2/${encodeURIComponent(orderId)}/status`, {
      method: 'GET',
      headers: {
        Authorization: getAuthHeader(),
        Accept: 'application/json',
      },
    });

    const data = await response.json();
    return {
      orderId: data.order_id,
      transactionId: data.transaction_id,
      transactionStatus: data.transaction_status,
      statusCode: data.status_code,
      grossAmount: data.gross_amount,
      settlementTime: data.settlement_time,
      signatureKey: data.signature_key,
      raw: data,
    };
  } catch (error) {
    console.error('[Midtrans Status Check Error]', error.message);
    return {
      orderId,
      transactionStatus: 'pending',
      error: error.message,
    };
  }
}

/**
 * Verifikasi signature webhook dari Midtrans
 */
function verifyWebhookSignature(body) {
  if (!isConfigured()) return false;
  if (!body || !body.signature_key) return false;

  const orderId = body.order_id || '';
  const statusCode = body.status_code || '';
  const grossAmount = body.gross_amount || '';

  const input = `${orderId}${statusCode}${grossAmount}${MIDTRANS_SERVER_KEY}`;
  const hash = crypto.createHash('sha512').update(input).digest('hex');

  const received = Buffer.from(String(body.signature_key), 'utf8');
  const expected = Buffer.from(hash, 'utf8');
  return received.length === expected.length &&
    crypto.timingSafeEqual(expected, received);
}

module.exports = {
  isConfigured,
  createQrisTransaction,
  checkTransactionStatus,
  verifyWebhookSignature,
  MIDTRANS_CLIENT_KEY,
  IS_PRODUCTION,
};
