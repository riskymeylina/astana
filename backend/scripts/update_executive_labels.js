const pool = require('../src/config/db');

async function updateExecutiveLabels() {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    await conn.query(`
      UPDATE buyer_records 
      SET data_label = 'BAST & Serah Terima Selesai', 
          notes = 'Pembelian unit hunian via Kantor Pemasaran Resmi PT Astana Karya Bandawasa. Berkas administrasi dan Berita Acara Serah Terima (BAST) kunci unit Prambanan Village Kav. E02 telah lengkap dan sah.' 
      WHERE full_name LIKE '%Aswin%'
    `);

    await conn.query(`
      UPDATE buyer_records 
      SET data_label = 'Dokumentasi Kepemilikan Sah', 
          notes = 'Pembelian unit hunian via Kantor Pemasaran Resmi PT Astana Karya Bandawasa. Dokumentasi legalitas kepemilikan dan serah terima unit hunian Wedomartani telah lengkap dan sah.' 
      WHERE full_name LIKE '%Ira%'
    `);

    await conn.query(`
      UPDATE historical_sales 
      SET data_label = 'Dokumen Resmi Penjualan', 
          notes = 'Pelunasan unit hunian Prambanan Village Kav. E02 (BAST & Kunci Selesai)' 
      WHERE property_name_snapshot LIKE '%Prambanan%'
    `);

    await conn.query(`
      UPDATE historical_sales 
      SET data_label = 'Dokumen Resmi Penjualan', 
          notes = 'Pelunasan unit hunian Wedomartani (Dokumentasi Kepemilikan Sah)' 
      WHERE property_name_snapshot LIKE '%Wedomartani%'
    `);

    await conn.commit();
    console.log('✅ Berhasil memperbarui label dan catatan ke format eksekutif profesional!');
    process.exit(0);
  } catch (err) {
    await conn.rollback();
    console.error('❌ Gagal memperbarui:', err);
    process.exit(1);
  } finally {
    conn.release();
  }
}

updateExecutiveLabels();

