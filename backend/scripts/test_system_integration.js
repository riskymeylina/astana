require('dotenv').config();
const http = require('http');
const { createMigrationConnection } = require('../src/utils/migration');

function request(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const headers = {};
    if (body) headers['Content-Type'] = 'application/json';
    if (token) headers['Authorization'] = 'Bearer ' + token;
    const req = http.request(
      { host: 'localhost', port: 3000, path, method, headers },
      (res) => {
        let d = '';
        res.on('data', c => d += c);
        res.on('end', () => {
          try { resolve({ status: res.statusCode, body: JSON.parse(d) }); }
          catch(e) { resolve({ status: res.statusCode, raw: d.slice(0, 400) }); }
        });
      }
    );
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

let pass = 0, fail = 0;
function chk(ok, msg) {
  if (ok) { console.log('[PASS] ' + msg); pass++; }
  else { console.log('[FAIL] ' + msg); fail++; }
}

(async () => {
  console.log('=====================================================');
  console.log('   FULL 3-ROLE INTEGRATION TEST - PT Astana Karya  ');
  console.log('=====================================================');

  // Pre-cleanup: ensure test property 26 is clean & available
  try {
    const db = await createMigrationConnection();
    await db.query(`UPDATE property_purchases SET status = 'cancelled' WHERE property_id = 26 AND status IN ('pending_payment', 'payment_uploaded', 'payment_review')`);
    await db.query(`UPDATE properties SET status = 'Tersedia' WHERE id_property = 26`);
    await db.end();
  } catch (e) {
    console.warn('Pre-cleanup warning:', e.message);
  }

  // ── STEP 1: Login all 3 roles ──────────────────────────────
  console.log('\n[1] AUTHENTICATION - 3 ROLES');
  const bl = await request('POST', '/api/auth/login', { email: 'roni@gmail.com', password: 'password123' });
  const ml = await request('POST', '/api/auth/login', { email: 'staf@gmail.com', password: 'password123' });
  const al = await request('POST', '/api/auth/login', { email: 'admin@gmail.com', password: 'password123' });
  const bt = bl.body.token, mt = ml.body.token, at = al.body.token;
  chk(!!bt, 'Pembeli (roni@gmail.com) login berhasil');
  chk(!!mt, 'Staf/Marketing (staf@gmail.com) login berhasil');
  chk(!!at, 'Admin (admin@gmail.com) login berhasil');
  chk(bl.body.user?.role === 'pembeli', 'Role Pembeli terverifikasi');
  chk(ml.body.user?.role === 'staf', 'Role Staf terverifikasi');
  chk(al.body.user?.role === 'admin', 'Role Admin terverifikasi');

  // ── STEP 2: Properties & Gallery ──────────────────────────
  console.log('\n[2] PROPERTIES & GALLERY DATABASE SYNC');
  const pl = await request('GET', '/api/properties');
  const props = pl.body.properties || [];
  chk(pl.status === 200, 'GET /api/properties -> 200 OK');
  chk(props.length >= 10, `10 Properti tersinkronisasi: ${props.length} ditemukan`);

  for (const id of [25, 26, 27, 28, 29, 30, 31, 32, 33, 34]) {
    const d = await request('GET', '/api/properties/' + id);
    const g = d.body.property?.gallery || [];
    chk(d.status === 200 && g.length >= 5,
      `Properti ${id}: ${(d.body.property?.title || '?').slice(0, 38)} -> ${g.length} foto galeri unik`);
  }

  // Verify all gallery images are accessible via HTTP
  const p26det = await request('GET', '/api/properties/26');
  const p26gallery = p26det.body.property?.gallery || [];
  let imgOk = 0, imgFail = 0;
  for (const item of p26gallery) {
    const imgPath = new URL(item.imageUrl).pathname;
    const imgRes = await request('GET', imgPath);
    if (imgRes.status === 200) imgOk++; else imgFail++;
  }
  chk(imgFail === 0, `Semua ${imgOk}/${p26gallery.length} gambar galeri Properti 26 dapat diakses (HTTP 200)`);

  // ── STEP 3: Buyer Workflow ─────────────────────────────────
  console.log('\n[3] BUYER WORKFLOW');

  const sv = await request('POST', '/api/surveys', {
    propertyId: 26, requestedDate: '2026-10-28', requestedTime: '10:00', notes: 'Ingin survei pagi hari'
  }, bt);
  chk(sv.status === 201, 'Pembeli buat permintaan survei: ' + sv.body.message);
  const svId = sv.body.surveyRequest?.id;

  const cn = await request('POST', '/api/consultations', {
    propertyId: 26, topic: 'Simulasi KPR Grand Limasan',
    preferredContactMethod: 'WhatsApp', message: 'Mohon info simulasi cicilan KPR untuk Tipe 65 Grand Limasan'
  }, bt);
  chk(cn.status === 201, 'Pembeli buat konsultasi: ' + cn.body.message);

  const pur = await request('POST', '/api/purchases', {
    propertyId: 26, paymentMethod: 'Cash Payment',
    buyerName: 'Rony Parulian', buyerPhone: '081234567890', buyerAddress: 'Jl. Contoh No.1, Klaten',
    notes: 'Pemesanan unit Grand Limasan'
  }, bt);
  chk(pur.status === 201, 'Pembeli buat pesanan properti: ' + pur.body.message);
  const purId = pur.body.purchase?.id || pur.body.order?.id;

  const myOrders = await request('GET', '/api/purchases/my-orders', null, bt);
  chk(myOrders.status === 200, `Pembeli lihat pesanan sendiri: ${myOrders.body.purchases?.length || myOrders.body.orders?.length || 0} pesanan`);

  const myNotifs = await request('GET', '/api/notifications', null, bt);
  chk(myNotifs.status === 200, `Pembeli lihat notifikasi: ${myNotifs.body.notifications?.length || 0} notifikasi`);

  // ── STEP 4: Marketing Workflow ─────────────────────────────
  console.log('\n[4] MARKETING (STAF) WORKFLOW');

  const mktSv = await request('GET', '/api/surveys/requests', null, mt);
  chk(mktSv.status === 200, `Staf lihat semua permintaan survei: ${mktSv.body.surveys?.length || 0} survei`);

  const mktCn = await request('GET', '/api/consultations/requests', null, mt);
  chk(mktCn.status === 200, `Staf lihat semua konsultasi: ${mktCn.body.consultations?.length || 0} konsultasi`);

  const mktOrd = await request('GET', '/api/purchases/orders', null, mt);
  chk(mktOrd.status === 200, `Staf lihat semua pesanan: ${mktOrd.body.purchases?.length || mktOrd.body.orders?.length || 0} pesanan`);

  // Marketing approve survey
  if (svId) {
    const appSv = await request('PATCH', '/api/surveys/' + svId + '/status', {
      status: 'approved', scheduledAt: '2026-10-28T10:00:00'
    }, mt);
    chk(appSv.status === 200, `Staf setujui survei #${svId}: ${appSv.body.message}`);
  }

  // Marketing changes property status -> real-time sync test
  const setBook = await request('PATCH', '/api/properties/26/status', { status: 'Sedang Dibooking' }, mt);
  chk(setBook.status === 200, 'Staf ubah status properti 26 -> Sedang Dibooking');

  // Buyer immediately sees it (no cache)
  const chkProp = await request('GET', '/api/properties/26');
  chk(chkProp.body.property?.status === 'Sedang Dibooking',
    'Real-time sync: Pembeli langsung lihat status "Sedang Dibooking"');

  const revert = await request('PATCH', '/api/properties/26/status', { status: 'Tersedia' }, mt);
  chk(revert.status === 200, 'Staf kembalikan status properti 26 -> Tersedia');

  // ── STEP 5: Admin Workflow ─────────────────────────────────
  console.log('\n[5] ADMIN WORKFLOW');

  const adProps = await request('GET', '/api/admin/properties', null, at);
  chk(adProps.status === 200, `Admin lihat semua properti: ${adProps.body.properties?.length || 0}`);

  const adInv = await request('GET', '/api/admin/invoices', null, at);
  chk(adInv.status === 200, `Admin lihat invoice/transaksi: ${adInv.body.invoices?.length || 0}`);

  const adCn = await request('GET', '/api/consultations/requests', null, at);
  chk(adCn.status === 200, `Admin lihat semua konsultasi: ${adCn.body.consultations?.length || 0}`);

  const adUsr = await request('GET', '/api/admin/users', null, at);
  chk(adUsr.status === 200, `Admin lihat semua users: ${adUsr.body.users?.length || 0} user`);

  const adSv = await request('GET', '/api/surveys/requests', null, at);
  chk(adSv.status === 200, `Admin lihat semua survei: ${adSv.body.surveys?.length || 0}`);

  // ── STEP 6: Access Control ─────────────────────────────────
  console.log('\n[6] ACCESS CONTROL (ROLE-BASED AUTHORIZATION)');

  const buyerAdmin = await request('GET', '/api/admin/properties', null, bt);
  chk(buyerAdmin.status === 403, `Pembeli tidak bisa akses admin route: ${buyerAdmin.status}`);

  const mktAdminUsers = await request('GET', '/api/admin/users', null, mt);
  chk(mktAdminUsers.status === 403, `Staf tidak bisa akses admin/users: ${mktAdminUsers.status}`);

  const guestPurchase = await request('POST', '/api/purchases', { propertyId: 26, paymentMethod: 'Cash Payment', buyerName: 'X' });
  chk(guestPurchase.status === 401, `Tamu tidak bisa buat pesanan (unauthorized): ${guestPurchase.status}`);

  const guestSurvey = await request('POST', '/api/surveys', { propertyId: 26, requestedDate: '2026-10-28' });
  chk(guestSurvey.status === 401, `Tamu tidak bisa buat permintaan survei: ${guestSurvey.status}`);

  // Post-cleanup: reset test order
  try {
    const db = await createMigrationConnection();
    await db.query(`UPDATE property_purchases SET status = 'cancelled' WHERE property_id = 26`);
    await db.query(`UPDATE properties SET status = 'Tersedia' WHERE id_property = 26`);
    await db.end();
  } catch (e) {}

  // ── SUMMARY ────────────────────────────────────────────────
  console.log('\n=====================================================');
  console.log(`HASIL TEST: ${pass} PASS | ${fail} FAIL`);
  console.log('=====================================================');
  process.exit(fail > 0 ? 1 : 0);
})().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
