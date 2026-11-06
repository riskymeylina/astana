require('dotenv').config();
const { createMigrationConnection } = require('../src/utils/migration');

const propertiesData = [
  // 1. Prambanan Village - Tipe 85 (2 Lantai)
  {
    title: 'Prambanan Village - Tipe 85 (2 Lantai)',
    category: 'Prambanan Village',
    location: 'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 685000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/prambanan_tipe_85.jpg',
        title: 'Tampak Depan (2 Lantai)',
        subtitle: 'Fasad Utama Limasan Modern 2 Lantai',
        d1: 'Bata ekspos & ukiran kayu jati',
        d2: 'Balkon atas & carport luas',
        order: 1
      },
      {
        url: '/uploads/properties/pv_85_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Interior Mewah 2 Lantai Nuansa Jawa',
        d1: 'Ruang tamu elegan dengan plafon void tinggi',
        d2: 'Pintu gebyok ukir jati & lantai granit premium',
        order: 2
      },
      {
        url: '/uploads/properties/pv_85_ruang_keluarga.jpg',
        title: 'Ruang Keluarga',
        subtitle: 'Area Kumpul Keluarga 2 Lantai',
        d1: 'Pencahayaan alami & sirkulasi udara baik',
        d2: 'Dekat taman samping & balkon',
        order: 3
      },
      {
        url: '/uploads/properties/pv_85_kamar_tidur.jpg',
        title: 'Kamar Tidur Utama',
        subtitle: 'Master Bedroom Lantai 1 Mewah',
        d1: 'Desain hangat & estetik, headboard ukir jati',
        d2: 'Kamar mandi dalam & balkon pribadi',
        order: 4
      },
      {
        url: '/uploads/properties/pv_85_kamar_tidur2.jpg',
        title: 'Kamar Tidur Lantai 2',
        subtitle: 'Kamar Tidur View Pegunungan Klaten',
        d1: 'View menghadap pegunungan & sawah hijau',
        d2: 'Balkon lantai 2 & jendela panoramik',
        order: 5
      },
      {
        url: '/uploads/properties/pv_85_dapur.jpg',
        title: 'Dapur Bersih',
        subtitle: 'Area Dapur Modern 2 Lantai',
        d1: 'Kitchen set minimalis rapi & modern',
        d2: 'Wastafel stainless & rak bumbu lengkap',
        order: 6
      },
      {
        url: '/uploads/properties/pv_85_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Bersih Modern',
        d1: 'Sanitair modern & shower',
        d2: 'Keramik premium anti-slip',
        order: 7
      }
    ]
  },

  // 2. Prambanan Village - Tipe 65 (Grand Limasan)
  {
    title: 'Prambanan Village - Tipe 65 (Grand Limasan)',
    category: 'Prambanan Village',
    location: 'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 495000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/prambanan_tipe_65.jpg',
        title: 'Tampak Depan (Grand Limasan)',
        subtitle: 'Fasad Lebar Etnik Jawa Modern',
        d1: 'Pintu Gebyok ukir jati mewah',
        d2: 'Halaman & carport paving luas',
        order: 1
      },
      {
        url: '/uploads/properties/pv_65_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Interior Limasan Klasik Jawa Tradisional',
        d1: 'Langit-langit kayu tinggi khas Limasan & dekorasi batik',
        d2: 'Pintu gebyok ukir & suasana asri alami',
        order: 2
      },
      {
        url: '/uploads/properties/pv_65_kamar_tidur.jpg',
        title: 'Kamar Tidur Utama',
        subtitle: 'Kamar Tidur Nyaman Grand Limasan',
        d1: 'Ruangan luas & jendela lebar kayu jati',
        d2: 'Pencahayaan alami maksimal',
        order: 3
      },
      {
        url: '/uploads/properties/pv_65_kamar_tidur2.jpg',
        title: 'Kamar Tidur Anak',
        subtitle: 'Kamar Tidur Kedua',
        d1: 'Cocok untuk anak/ruang kerja',
        d2: 'Kusen kayu jati & sirkulasi baik',
        order: 4
      },
      {
        url: '/uploads/properties/pv_65_dapur.jpg',
        title: 'Dapur Minimalis',
        subtitle: 'Dapur & Meja Makan Tipe 65',
        d1: 'Area memasak bersih & lapang',
        d2: 'Ventilasi udara terbuka alami',
        order: 5
      },
      {
        url: '/uploads/properties/pv_65_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Modern Tipe 65',
        d1: 'Shower & closet duduk berkualitas',
        d2: 'Keramik anti-slip estetik',
        order: 6
      }
    ]
  },

  // 3. Prambanan Village - Tipe 45 (Joglo Modern)
  {
    title: 'Prambanan Village - Tipe 45 (Joglo Modern)',
    category: 'Prambanan Village',
    location: 'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 385000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/prambanan_tipe_45.jpg',
        title: 'Tampak Depan (Joglo Asri)',
        subtitle: 'Fasad Joglo Tropis Modern Bata Ekspos',
        d1: 'Bata ekspos merah & ukiran kayu jendela',
        d2: 'Taman bunga & teras depan asri',
        order: 1
      },
      {
        url: '/uploads/properties/pv_45_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Interior Joglo Modern - View Candi Prambanan',
        d1: 'Bata ekspos & kayu jati, nuansa etnik modern',
        d2: 'View candi Prambanan dari jendela panoramik',
        order: 2
      },
      {
        url: '/uploads/properties/pv_45_kamar_tidur.jpg',
        title: 'Kamar Tidur Utama',
        subtitle: 'Kamar Tidur Nyaman Joglo',
        d1: 'Penataan fungsional & tenang',
        d2: 'Sirkulasi udara segar alami dari taman',
        order: 3
      },
      {
        url: '/uploads/properties/pv_45_dapur.jpg',
        title: 'Dapur',
        subtitle: 'Dapur Bersih Kompak Tipe 45',
        d1: 'Meja dapur cor & kitchen sink modern',
        d2: 'Mudah dibersihkan & ventilasi baik',
        order: 4
      },
      {
        url: '/uploads/properties/pv_45_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Bersih Tipe 45',
        d1: 'Shower & kloset berkualitas',
        d2: 'Dinding keramik estetik',
        order: 5
      }
    ]
  },

  // 4. Prambanan Village - Tipe 36 (Limasan Minimalis)
  {
    title: 'Prambanan Village - Tipe 36 (Limasan Minimalis)',
    category: 'Prambanan Village',
    location: 'Prambanan Village III, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 295000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/prambanan_tipe_36.jpg',
        title: 'Tampak Depan (Limasan Minimalis)',
        subtitle: 'Fasad Limasan Compact & Elegan',
        d1: 'Lisplang ukir putih & bata ekspos',
        d2: 'Carport & jalan setapak batu alam',
        order: 1
      },
      {
        url: '/uploads/properties/pv_36_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Interior Limasan Minimalis Nyaman',
        d1: 'Ruangan compact hangat & nyaman nuansa Jawa',
        d2: 'Plafon kayu tinggi & jendela ventilasi jati',
        order: 2
      },
      {
        url: '/uploads/properties/pv_36_kamar_tidur.jpg',
        title: 'Kamar Tidur',
        subtitle: 'Kamar Tidur Fungsional Tipe 36',
        d1: 'Kenyamanan istirahat maksimal',
        d2: 'Jendela ventilasi asri & sirkulasi udara',
        order: 3
      },
      {
        url: '/uploads/properties/pv_36_dapur.jpg',
        title: 'Dapur',
        subtitle: 'Dapur Kompak Efisien Tipe 36',
        d1: 'Penataan hemat ruang & praktis',
        d2: 'Fasilitas memasak lengkap',
        order: 4
      },
      {
        url: '/uploads/properties/pv_36_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Bersih Tipe 36',
        d1: 'Bersih & higienis',
        d2: 'Shower & closet duduk',
        order: 5
      }
    ]
  },

  // 5. Joglo Amerta Prambanan
  {
    title: 'Joglo Amerta Prambanan',
    category: 'Joglo Amerta',
    location: 'Joglo Amerta Prambanan, Jl. Manisrenggo, Bener, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 425000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/joglo_amerta_prambanan.jpg',
        title: 'Tampak Depan (Klasik Modern)',
        subtitle: 'Fasad Mewah Klasik Modern Eropa-Jawa',
        d1: 'Pilar lengkung megah & pintu tinggi elegan',
        d2: 'Halaman depan & carport luas',
        order: 1
      },
      {
        url: '/uploads/properties/ja_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Interior Ruang Tamu Mewah Joglo Amerta',
        d1: 'Plafon tinggi & pencahayaan hangat nuansa premium',
        d2: 'Lantai granit premium & ornamen mewah',
        order: 2
      },
      {
        url: '/uploads/properties/ja_ruang_keluarga.jpg',
        title: 'Ruang Keluarga',
        subtitle: 'Area Kumpul Keluarga Joglo Amerta',
        d1: 'Ruangan lapang & sirkulasi udara optimal',
        d2: 'Kaca jendela besar & view taman',
        order: 3
      },
      {
        url: '/uploads/properties/ja_kamar_tidur.jpg',
        title: 'Kamar Tidur Utama',
        subtitle: 'Master Bedroom Joglo Amerta',
        d1: 'Desain estetik & tenang nuansa Jawa',
        d2: 'Kamar mandi dalam & pencahayaan mewah',
        order: 4
      },
      {
        url: '/uploads/properties/ja_kamar_tidur2.jpg',
        title: 'Kamar Tidur Anak',
        subtitle: 'Kamar Tidur Kedua Joglo Amerta',
        d1: 'Fungsional untuk anak atau ruang kerja',
        d2: 'Pencahayaan alami & sirkulasi udara baik',
        order: 5
      },
      {
        url: '/uploads/properties/ja_dapur.jpg',
        title: 'Dapur Minimalis',
        subtitle: 'Dapur Bersih Joglo Amerta',
        d1: 'Kitchen counter cor & wastafel modern',
        d2: 'Ventilasi udara baik & bersih',
        order: 6
      },
      {
        url: '/uploads/properties/ja_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Modern Joglo Amerta',
        d1: 'Sanitair lengkap, shower & closet duduk',
        d2: 'Keramik dinding estetik premium',
        order: 7
      }
    ]
  },

  // 6. Bhumi Svarga Prambanan - Tipe Joglo Bata Klasik
  {
    title: 'Bhumi Svarga Prambanan - Tipe Joglo Bata Klasik',
    category: 'Bhumi Svarga',
    location: 'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 495000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/bhumi_svarga_tipe_joglo_bata.jpg',
        title: 'Tampak Depan (Joglo Bata Klasik)',
        subtitle: 'Fasad Joglo Bata Ekspos Klasik Jawa',
        d1: 'Bata ekspos merah & atap genteng joglo',
        d2: 'Pintu gebyok ukir jati & taman depan',
        order: 1
      },
      {
        url: '/uploads/properties/bs_joglo_bata_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Interior Klasik Jawa Modern',
        d1: 'Suasana hangat & plafon tinggi khas joglo',
        d2: 'Lantai keramik premium & ventilasi baik',
        order: 2
      },
      {
        url: '/uploads/properties/bs_joglo_bata_kamar_tidur.jpg',
        title: 'Kamar Tidur Utama',
        subtitle: 'Kamar Tidur Nyaman Joglo Bata',
        d1: 'Desain tenang & fungsional nuansa Jawa',
        d2: 'Pencahayaan alami dari jendela kayu jati',
        order: 3
      },
      {
        url: '/uploads/properties/bs_joglo_bata_dapur.jpg',
        title: 'Dapur',
        subtitle: 'Dapur Bersih Tipe Joglo Bata',
        d1: 'Kitchen set rapi & modern',
        d2: 'Ventilasi baik & bersih',
        order: 4
      },
      {
        url: '/uploads/properties/bs_joglo_bata_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Modern Joglo Bata',
        d1: 'Sanitair lengkap & shower',
        d2: 'Keramik estetik premium',
        order: 5
      }
    ]
  },

  // 7. Bhumi Svarga Prambanan - Tipe Limasan Kembar
  {
    title: 'Bhumi Svarga Prambanan - Tipe Limasan Kembar',
    category: 'Bhumi Svarga',
    location: 'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 385000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/bhumi_svarga_tipe_limasan_kembar.jpg',
        title: 'Tampak Depan (Limasan Kembar)',
        subtitle: 'Unit Kembar Limasan Area Sawah',
        d1: 'Desain serasi berpasangan & taman kolektif',
        d2: 'View area sawah & suasana asri',
        order: 1
      },
      {
        url: '/uploads/properties/bs_limasan_kembar_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Interior Limasan Kembar Hangat',
        d1: 'Ruangan lapang & sirkulasi baik khas limasan',
        d2: 'Pintu ukir kayu jati & dekorasi etnik',
        order: 2
      },
      {
        url: '/uploads/properties/bs_limasan_kembar_kamar_tidur.jpg',
        title: 'Kamar Tidur Utama',
        subtitle: 'Kamar Tidur Limasan Kembar',
        d1: 'Ruangan fungsional & estetik nuansa kayu',
        d2: 'Jendela lebar & ventilasi asri sawah',
        order: 3
      },
      {
        url: '/uploads/properties/bs_limasan_kembar_dapur.jpg',
        title: 'Dapur',
        subtitle: 'Dapur Kompak Limasan Kembar',
        d1: 'Area memasak bersih & lapang',
        d2: 'Fasilitas dapur lengkap',
        order: 4
      },
      {
        url: '/uploads/properties/bs_limasan_kembar_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Limasan Kembar',
        d1: 'Shower & closet duduk berkualitas',
        d2: 'Keramik anti-slip premium',
        order: 5
      }
    ]
  },

  // 8. Bhumi Svarga Prambanan - Tipe Joglo Modern
  {
    title: 'Bhumi Svarga Prambanan - Tipe Joglo Modern',
    category: 'Bhumi Svarga',
    location: 'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 350000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/bhumi_svarga_tipe_joglo_modern.jpg',
        title: 'Tampak Depan (Joglo Modern)',
        subtitle: 'Fasad Joglo Modern Putih & Bata',
        d1: 'Cat putih bersih & atap joglo genteng merah',
        d2: 'Taman bunga depan & jalan setapak',
        order: 1
      },
      {
        url: '/uploads/properties/bs_joglo_modern_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Ruang Tamu Cerah Joglo Modern',
        d1: 'Interior terang & modern nuansa Jawa kontemporer',
        d2: 'Plafon tinggi khas joglo & lantai premium',
        order: 2
      },
      {
        url: '/uploads/properties/bs_joglo_modern_kamar_tidur.jpg',
        title: 'Kamar Tidur Utama',
        subtitle: 'Kamar Tidur Joglo Modern',
        d1: 'Desain minimalis & nyaman',
        d2: 'Pencahayaan alami maksimal dari jendela lebar',
        order: 3
      },
      {
        url: '/uploads/properties/bs_joglo_modern_dapur.jpg',
        title: 'Dapur',
        subtitle: 'Dapur Minimalis Joglo Modern',
        d1: 'Penataan rapi & efisien',
        d2: 'Kitchen sink modern & bersih',
        order: 4
      },
      {
        url: '/uploads/properties/bs_joglo_modern_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Joglo Modern',
        d1: 'Bersih & modern sanitair lengkap',
        d2: 'Shower & closet duduk premium',
        order: 5
      }
    ]
  },

  // 9. Bhumi Svarga Prambanan - Tipe Limasan Luas
  {
    title: 'Bhumi Svarga Prambanan - Tipe Limasan Luas',
    category: 'Bhumi Svarga',
    location: 'Bhumi Svarga Prambanan, Area Sawah, Bugisan, Kec. Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 445000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/bhumi_svarga_tipe_limasan_luas.jpg',
        title: 'Tampak Depan (Limasan Luas)',
        subtitle: 'Fasad Limasan Bata Lebar Motif Jawa',
        d1: 'Bata ekspos luas & pagar motif batik Jawa',
        d2: 'Carport lebar & halaman representatif',
        order: 1
      },
      {
        url: '/uploads/properties/bs_limasan_luas_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Ruang Tamu Luas Elegan',
        d1: 'Ruangan lega & elegan khas limasan luas',
        d2: 'Lantai granit & pencahayaan hangat optimal',
        order: 2
      },
      {
        url: '/uploads/properties/bs_limasan_luas_ruang_keluarga.jpg',
        title: 'Ruang Keluarga',
        subtitle: 'Area Kumpul Keluarga Limasan',
        d1: 'Ruang keluarga lapang & nyaman',
        d2: 'Sirkulasi udara optimal & ventilasi baik',
        order: 3
      },
      {
        url: '/uploads/properties/bs_limasan_luas_kamar_tidur.jpg',
        title: 'Kamar Tidur Utama',
        subtitle: 'Kamar Tidur Utama Limasan Luas',
        d1: 'Desain hangat & luas nuansa Jawa',
        d2: 'Kamar mandi dalam & sirkulasi baik',
        order: 4
      },
      {
        url: '/uploads/properties/bs_limasan_luas_kamar_tidur2.jpg',
        title: 'Kamar Tidur 2',
        subtitle: 'Kamar Tidur Kedua Limasan Luas',
        d1: 'Fungsional & nyaman dengan jendela lebar',
        d2: 'Pencahayaan alami & sirkulasi baik',
        order: 5
      },
      {
        url: '/uploads/properties/bs_limasan_luas_dapur.jpg',
        title: 'Dapur',
        subtitle: 'Dapur Luas Limasan',
        d1: 'Area memasak lega & modern lengkap',
        d2: 'Ventilasi udara terbuka & kitchen set rapi',
        order: 6
      },
      {
        url: '/uploads/properties/bs_limasan_luas_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Limasan Luas',
        d1: 'Sanitair lengkap & modern premium',
        d2: 'Keramik premium & anti-slip',
        order: 7
      }
    ]
  },

  // 10. Bhumi Svarga Prambanan - Tipe 2 Lantai (Blok C)
  {
    title: 'Bhumi Svarga Prambanan - Tipe 2 Lantai (Blok C)',
    category: 'Bhumi Svarga',
    location: 'Bhumi Svarga Prambanan Blok C, Jl. Bhumi Svarga Blok C no. 2, Area Sawah, Bugisan, Prambanan, Kabupaten Klaten, Jawa Tengah 57454',
    price: 685000000,
    status: 'Tersedia',
    gallery: [
      {
        url: '/uploads/properties/bhumi_svarga_tipe_2lantai.jpg',
        title: 'Tampak Depan (2 Lantai)',
        subtitle: 'Fasad Joglo 2 Lantai Bata Ekspos Premium',
        d1: 'Bata ekspos 2 lantai & atap joglo bertingkat',
        d2: 'Balkon lantai 2, taman bunga & view pegunungan',
        order: 1
      },
      {
        url: '/uploads/properties/bs_2lantai_ruang_tamu.jpg',
        title: 'Ruang Tamu',
        subtitle: 'Ruang Tamu Lantai 1 Mewah',
        d1: 'Interior elegan dengan plafon tinggi khas joglo',
        d2: 'Pintu ukir gebyok & lantai granit premium',
        order: 2
      },
      {
        url: '/uploads/properties/bs_2lantai_ruang_keluarga.jpg',
        title: 'Ruang Keluarga',
        subtitle: 'Ruang Keluarga Lantai 1',
        d1: 'Area santai keluarga yang lapang & nyaman',
        d2: 'Pencahayaan alami & sirkulasi baik',
        order: 3
      },
      {
        url: '/uploads/properties/bs_2lantai_kamar_tidur.jpg',
        title: 'Kamar Tidur Utama',
        subtitle: 'Master Bedroom Lantai 1 Premium',
        d1: 'Desain mewah & tenang khas Jawa modern',
        d2: 'Kamar mandi dalam & walk-in closet',
        order: 4
      },
      {
        url: '/uploads/properties/bs_2lantai_kamar_tidur2.jpg',
        title: 'Kamar Tidur Lantai 2',
        subtitle: 'Kamar Tidur Lantai 2 View Balkon',
        d1: 'View balkon & pegunungan Klaten indah',
        d2: 'Kamar luas & pencahayaan maksimal',
        order: 5
      },
      {
        url: '/uploads/properties/bs_2lantai_dapur.jpg',
        title: 'Dapur Modern',
        subtitle: 'Dapur Bersih 2 Lantai Premium',
        d1: 'Kitchen set lengkap & modern',
        d2: 'Wastafel & area memasak luas rapi',
        order: 6
      },
      {
        url: '/uploads/properties/bs_2lantai_kamar_mandi.jpg',
        title: 'Kamar Mandi',
        subtitle: 'Kamar Mandi Premium 2 Lantai',
        d1: 'Sanitair mewah & shower modern',
        d2: 'Keramik premium & dinding estetik',
        order: 7
      }
    ]
  }
];

async function sync() {
  const db = await createMigrationConnection();
  console.log('Synchronizing database properties and gallery...');

  try {
    for (const p of propertiesData) {
      // Find property by title
      const [existing] = await db.query('SELECT id_property FROM properties WHERE title = ?', [p.title]);
      let propId;

      if (existing.length > 0) {
        propId = existing[0].id_property;
        await db.query(
          'UPDATE properties SET category = ?, location = ?, price = ?, status = ? WHERE id_property = ?',
          [p.category, p.location, p.price, p.status, propId]
        );
        console.log(`Updated property: [${propId}] ${p.title}`);
      } else {
        const [res] = await db.query(
          'INSERT INTO properties (title, category, location, price, status) VALUES (?, ?, ?, ?, ?)',
          [p.title, p.category, p.location, p.price, p.status]
        );
        propId = res.insertId;
        console.log(`Inserted property: [${propId}] ${p.title}`);
      }

      // Delete existing gallery images for this property and insert fresh distinct images
      await db.query('DELETE FROM property_gallery_images WHERE property_id = ?', [propId]);

      for (const g of p.gallery) {
        await db.query(
          `INSERT INTO property_gallery_images
           (property_id, image_url, title, subtitle, detail_primary, detail_secondary, sort_order)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [propId, g.url, g.title, g.subtitle, g.d1, g.d2, g.order]
        );
      }
      console.log(`  -> Synced ${p.gallery.length} gallery images for [${propId}]`);
    }

    console.log('Database synchronization completed successfully!');
  } finally {
    await db.end();
  }
}

sync().catch(err => {
  console.error('Sync failed:', err);
  process.exit(1);
});
