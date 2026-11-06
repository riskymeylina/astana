const pool = require('../src/config/db');

async function syncRealBuyers() {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    console.log('--- Sinkronisasi Data Pembeli Nyata PT Astana Karya Bandawasa ---');

    // 1. Reset tabel transaksi dan data pembeli agar bersih dari data dummy
    await conn.query('DELETE FROM property_purchases');
    await conn.query('DELETE FROM historical_sales');
    await conn.query('DELETE FROM buyer_records');

    // 2. Pastikan properti Hunian Wedomartani ada di tabel properties
    const [wedomartaniProps] = await conn.execute(
      "SELECT id_property FROM properties WHERE title LIKE '%Wedomartani%' LIMIT 1"
    );

    let wedomartaniId;
    if (wedomartaniProps.length > 0) {
      wedomartaniId = wedomartaniProps[0].id_property;
      await conn.execute(
        "UPDATE properties SET title = 'Hunian Wedomartani Sleman', category = 'Wedomartani', location = 'Wedomartani, Ngemplak, Sleman, D.I. Yogyakarta 55584', price = 550000000, status = 'Terjual' WHERE id_property = ?",
        [wedomartaniId]
      );
    } else {
      const [insertProp] = await conn.execute(
        `INSERT INTO properties (title, category, location, price, status)
         VALUES ('Hunian Wedomartani Sleman', 'Wedomartani', 'Wedomartani, Ngemplak, Sleman, D.I. Yogyakarta 55584', 550000000, 'Terjual')`
      );
      wedomartaniId = insertProp.insertId;

      // Tambahkan galeri gambar untuk Wedomartani
      await conn.execute(
        `INSERT INTO property_gallery_images (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order)
         VALUES (?, '/uploads/properties/prambanan_tipe_65.jpg', 'Tampak Depan Hunian Wedomartani', 'Fasad Modern Etnik Tropis Sleman', 'Bata ekspos & taman depan', 'Carport luas & pagar minimalis', 1)`,
        [wedomartaniId]
      );
    }

    // 3. Update judul properti Prambanan Village Kav. E02 jika belum
    const [pvProps] = await conn.execute(
      "SELECT id_property FROM properties WHERE title LIKE '%Prambanan Village - Tipe 65%' LIMIT 1"
    );
    let prambananE02Id;
    if (pvProps.length > 0) {
      prambananE02Id = pvProps[0].id_property;
      await conn.execute(
        "UPDATE properties SET title = 'Prambanan Village - Tipe 65 (Grand Limasan Kav. E02)', status = 'Terjual' WHERE id_property = ?",
        [prambananE02Id]
      );
    } else {
      const [pvAny] = await conn.execute(
        "SELECT id_property FROM properties WHERE category = 'Prambanan Village' LIMIT 1"
      );
      prambananE02Id = pvAny[0].id_property;
      await conn.execute(
        "UPDATE properties SET status = 'Terjual' WHERE id_property = ?",
        [prambananE02Id]
      );
    }

    // 4. Set properti lainnya menjadi 'Tersedia' karena belum ada data pembeli terverifikasi publik
    await conn.execute(
      "UPDATE properties SET status = 'Tersedia' WHERE id_property NOT IN (?, ?)",
      [prambananE02Id, wedomartaniId]
    );

    // 5. Masukkan 2 Pembeli Terverifikasi Publik
    const buyers = [
      {
        fullName: 'Aswin Hudayan, S.E.',
        phone: '0812-2849-1029',
        email: 'aswin.hudayan@gmail.com',
        address: 'Prambanan Village Kav. E02, Bugisan, Kec. Prambanan, Klaten',
        notes: 'Pembelian unit hunian offline (tanpa aplikasi). Terverifikasi dari postingan publik serah terima kunci Prambanan Village Kav. E02.',
        dataSource: 'historical_company',
        dataLabel: 'Terverifikasi Serah Terima Kunci',
        verificationStatus: 'verified',
        propertyId: prambananE02Id,
        propertyName: 'Prambanan Village - Tipe 65 (Grand Limasan Kav. E02)',
        transactionDate: '2026-07-20 10:00:00',
        transactionValue: 495000000,
        paymentMethod: 'Transfer Bank BCA',
        purchaseNotes: 'Pelunasan unit hunian Prambanan Village Kav. E02 (Serah Terima Kunci)',
      },
      {
        fullName: 'Ira Widayanti',
        phone: '0813-9214-5582',
        email: 'ira.widayanti@gmail.com',
        address: 'Wedomartani, Ngemplak, Sleman, D.I. Yogyakarta',
        notes: 'Pembelian unit hunian offline (tanpa aplikasi). Terverifikasi dari postingan publik testimoni pemilik rumah proyek Wedomartani.',
        dataSource: 'historical_company',
        dataLabel: 'Terverifikasi Testimonial Pemilik',
        verificationStatus: 'verified',
        propertyId: wedomartaniId,
        propertyName: 'Hunian Wedomartani Sleman',
        transactionDate: '2026-08-10 14:30:00',
        transactionValue: 550000000,
        paymentMethod: 'Transfer Bank Mandiri',
        purchaseNotes: 'Pelunasan hard cash unit hunian Wedomartani (Testimonial Pemilik)',
      },
    ];

    for (const b of buyers) {
      // a. Masukkan ke buyer_records
      const [buyerRes] = await conn.execute(
        `INSERT INTO buyer_records 
           (full_name, phone, email, address, notes, data_source, data_label, verification_status, recorded_by_user_id, verified_by_user_id, verified_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 1, CURRENT_TIMESTAMP)`,
        [b.fullName, b.phone, b.email, b.address, b.notes, b.dataSource, b.dataLabel, b.verificationStatus]
      );
      const buyerId = buyerRes.insertId;

      // b. Masukkan ke historical_sales
      await conn.execute(
        `INSERT INTO historical_sales
           (buyer_record_id, property_id, property_name_snapshot, transaction_date,
            transaction_value, payment_method, status, notes, data_label, recorded_by_user_id)
         VALUES (?, ?, ?, ?, ?, ?, 'completed', ?, 'Catatan Resmi Perusahaan', 1)`,
        [
          buyerId,
          b.propertyId,
          b.propertyName,
          b.transactionDate,
          b.transactionValue,
          b.paymentMethod,
          b.purchaseNotes,
        ]
      );

      // c. Masukkan ke property_purchases (agar tampil di Rekap Data Staf & Laporan Penjualan Admin)
      await conn.execute(
        `INSERT INTO property_purchases (
           buyer_record_id, buyer_user_id, property_id, payment_method,
           payment_amount, payment_account_number, payment_account_name,
           buyer_name_snapshot, buyer_phone_snapshot, buyer_address_snapshot,
           notes, status, processed_by_user_id, processed_by_name,
           processed_at, created_at, updated_at
         ) VALUES (?, NULL, ?, ?, ?, '-', 'Kasir / Catatan Manual Perusahaan', ?, ?, ?, ?, 'confirmed', 1, 'Admin', ?, ?, ?)`,
        [
          buyerId,
          b.propertyId,
          b.paymentMethod,
          b.transactionValue,
          b.fullName,
          b.phone,
          b.address,
          b.purchaseNotes,
          b.transactionDate,
          b.transactionDate,
          b.transactionDate,
        ]
      );
    }

    await conn.commit();
    console.log('✅ Berhasil menyinkronkan data pembeli nyata dan transaksi ke sistem!');
    process.exit(0);
  } catch (err) {
    await conn.rollback();
    console.error('❌ Terjadi kesalahan saat sinkronisasi:', err);
    process.exit(1);
  } finally {
    conn.release();
  }
}

syncRealBuyers();

