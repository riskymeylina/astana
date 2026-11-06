const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

const uploadDir = path.join(__dirname, '..', 'uploads', 'properties');
const assetDir = path.join(__dirname, '..', '..', 'assets', 'images');

// 34 distinct photo IDs chosen for warm tropical, wooden, brick, ethnic, and modern aesthetic matching PT Astana Karya style
const imagesToFetch = {
  // Prambanan Village 85
  'pv_85_ruang_keluarga.jpg': 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=1200&q=80',
  'pv_85_dapur.jpg': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=1200&q=80',
  'pv_85_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?auto=format&fit=crop&w=1200&q=80',

  // Prambanan Village 65
  'pv_65_kamar_tidur.jpg': 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=1200&q=80',
  'pv_65_kamar_tidur2.jpg': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
  'pv_65_dapur.jpg': 'https://images.unsplash.com/photo-1507089947368-19c1da9775ae?auto=format&fit=crop&w=1200&q=80',
  'pv_65_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=1200&q=80',

  // Prambanan Village 45
  'pv_45_kamar_tidur.jpg': 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=80',
  'pv_45_dapur.jpg': 'https://images.unsplash.com/photo-1556912173-3bb406ef7e77?auto=format&fit=crop&w=1200&q=80',
  'pv_45_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1620626011761-996317b8d101?auto=format&fit=crop&w=1200&q=80',

  // Prambanan Village 36
  'pv_36_kamar_tidur.jpg': 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=1200&q=80',
  'pv_36_dapur.jpg': 'https://images.unsplash.com/photo-1565538810643-b5bdb714032a?auto=format&fit=crop&w=1200&q=80',
  'pv_36_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1604709177225-055f99402ea3?auto=format&fit=crop&w=1200&q=80',

  // Joglo Amerta
  'ja_ruang_tamu.jpg': 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
  'ja_ruang_keluarga.jpg': 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
  'ja_kamar_tidur.jpg': 'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1200&q=80',
  'ja_kamar_tidur2.jpg': 'https://images.unsplash.com/photo-1616047006789-b7af5afb8c20?auto=format&fit=crop&w=1200&q=80',
  'ja_dapur.jpg': 'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=1200&q=80',
  'ja_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1564540583246-9344192b1a50?auto=format&fit=crop&w=1200&q=80',

  // Bhumi Svarga Joglo Bata
  'bs_joglo_bata_ruang_tamu.jpg': 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&q=80',
  'bs_joglo_bata_kamar_tidur.jpg': 'https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=1200&q=80',
  'bs_joglo_bata_dapur.jpg': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=1200&q=80',
  'bs_joglo_bata_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1631679706909-1844bbd07221?auto=format&fit=crop&w=1200&q=80',

  // Bhumi Svarga Limasan Kembar
  'bs_limasan_kembar_ruang_tamu.jpg': 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80',
  'bs_limasan_kembar_kamar_tidur.jpg': 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=80',
  'bs_limasan_kembar_dapur.jpg': 'https://images.unsplash.com/photo-1507089947368-19c1da9775ae?auto=format&fit=crop&w=1200&q=80',
  'bs_limasan_kembar_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?auto=format&fit=crop&w=1200&q=80',

  // Bhumi Svarga Joglo Modern
  'bs_joglo_modern_ruang_tamu.jpg': 'https://images.unsplash.com/photo-1615873968403-89e068629265?auto=format&fit=crop&w=1200&q=80',
  'bs_joglo_modern_kamar_tidur.jpg': 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=1200&q=80',
  'bs_joglo_modern_dapur.jpg': 'https://images.unsplash.com/photo-1541123437800-1bb1317badc2?auto=format&fit=crop&w=1200&q=80',
  'bs_joglo_modern_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1507652313519-d4e9174996dd?auto=format&fit=crop&w=1200&q=80',

  // Bhumi Svarga Limasan Luas
  'bs_limasan_luas_ruang_tamu.jpg': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
  'bs_limasan_luas_ruang_keluarga.jpg': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
  'bs_limasan_luas_kamar_tidur.jpg': 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80',
  'bs_limasan_luas_kamar_tidur2.jpg': 'https://images.unsplash.com/photo-1499951360447-b19be8fe80f5?auto=format&fit=crop&w=1200&q=80',
  'bs_limasan_luas_dapur.jpg': 'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80',
  'bs_limasan_luas_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80',

  // Bhumi Svarga 2 Lantai
  'bs_2lantai_ruang_tamu.jpg': 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=1200&q=80',
  'bs_2lantai_ruang_keluarga.jpg': 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?auto=format&fit=crop&w=1200&q=80',
  'bs_2lantai_kamar_tidur.jpg': 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=80',
  'bs_2lantai_kamar_tidur2.jpg': 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=1200&q=80',
  'bs_2lantai_dapur.jpg': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=1200&q=80',
  'bs_2lantai_kamar_mandi.jpg': 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?auto=format&fit=crop&w=1200&q=80',
};

function downloadUrl(url, destPath) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return downloadUrl(res.headers.location, destPath).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
      }
      const stream = fs.createWriteStream(destPath);
      res.pipe(stream);
      stream.on('finish', () => {
        stream.close();
        resolve();
      });
      stream.on('error', reject);
    }).on('error', reject);
  });
}

async function run() {
  console.log('Downloading distinct gallery photos...');
  for (const [filename, url] of Object.entries(imagesToFetch)) {
    const uploadPath = path.join(uploadDir, filename);
    const assetPath = path.join(assetDir, filename);
    try {
      await downloadUrl(url, uploadPath);
      fs.copyFileSync(uploadPath, assetPath);
      const size = fs.statSync(uploadPath).size;
      console.log(`[OK] ${filename} (${Math.round(size / 1024)} KB)`);
    } catch (err) {
      console.error(`[ERR] ${filename}: ${err.message}`);
    }
  }

  // Also copy existing unique images to assets/images so Flutter has complete local fallback
  const existingFiles = [
    'pv_85_ruang_tamu.jpg',
    'pv_85_kamar_tidur.jpg',
    'pv_85_kamar_tidur2.jpg',
    'pv_65_ruang_tamu.jpg',
    'pv_45_ruang_tamu.jpg',
    'pv_36_ruang_tamu.jpg',
    'prambanan_tipe_85.jpg',
    'prambanan_tipe_65.jpg',
    'prambanan_tipe_45.jpg',
    'prambanan_tipe_36.jpg',
    'joglo_amerta_prambanan.jpg',
    'bhumi_svarga_tipe_joglo_bata.jpg',
    'bhumi_svarga_tipe_limasan_kembar.jpg',
    'bhumi_svarga_tipe_joglo_modern.jpg',
    'bhumi_svarga_tipe_limasan_luas.jpg',
    'bhumi_svarga_tipe_2lantai.jpg',
  ];

  for (const f of existingFiles) {
    const src = path.join(uploadDir, f);
    const dst = path.join(assetDir, f);
    if (fs.existsSync(src)) {
      fs.copyFileSync(src, dst);
    }
  }

  console.log('Done downloading and copying all property gallery images!');
}

run();
