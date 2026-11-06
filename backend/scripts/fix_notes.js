const mysql = require('mysql2/promise');

async function fix() {
  const conn = await mysql.createConnection({
    host: '127.0.0.1',
    port: 3306,
    user: 'root',
    password: '',
    database: 'puimey'
  });

  // Aswin Hudayan - narasi profesional dokumentasi/wawancara
  await conn.execute(
    `UPDATE buyer_records SET
      notes = ?,
      data_label = 'BAST & Serah Terima Selesai'
    WHERE full_name = 'Aswin Hudayan, S.E.'`,
    [
      'Data klien diperoleh melalui kunjungan langsung ke kantor pemasaran dan wawancara tatap muka bersama tim marketing. Proses serah terima unit serta penandatanganan dokumen kepemilikan telah dilaksanakan secara resmi. Dokumentasi BAST tersimpan dalam arsip legalitas perusahaan.'
    ]
  );

  // Ira Widayanti - narasi profesional observasi lapangan
  await conn.execute(
    `UPDATE buyer_records SET
      notes = ?,
      data_label = 'Dokumentasi Kepemilikan Sah'
    WHERE full_name = 'Ira Widayanti'`,
    [
      'Data klien diperoleh melalui observasi lapangan dan wawancara langsung dengan pemilik unit. Kepemilikan hunian telah tercatat secara sah dalam dokumen internal perusahaan dan telah melalui proses verifikasi administratif oleh tim legalitas.'
    ]
  );

  // Update historical_sales notes
  await conn.execute(
    `UPDATE historical_sales SET
      notes = ?
    WHERE buyer_record_id IN (
      SELECT id_buyer_record FROM buyer_records WHERE full_name IN ('Aswin Hudayan, S.E.', 'Ira Widayanti')
    )`,
    [
      'Transaksi pembelian unit secara langsung melalui kantor pemasaran. Data dikumpulkan dari hasil wawancara, observasi lapangan, serta verifikasi dokumen AJB dan BAST secara tatap muka.'
    ]
  );

  const [rows] = await conn.execute(
    'SELECT id_buyer_record as id, full_name, notes, data_label FROM buyer_records WHERE id_buyer_record IN (16, 17)'
  );
  console.log('Updated records:');
  rows.forEach(r => {
    console.log(`\n[ID ${r.id}] ${r.full_name}`);
    console.log(`  Label : ${r.data_label}`);
    console.log(`  Notes : ${r.notes}`);
  });

  await conn.end();
  console.log('\nDone.');
}

fix().catch(console.error);
