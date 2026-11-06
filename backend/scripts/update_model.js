const fs = require('fs');

let content = fs.readFileSync('lib/models/buyer_record_model.dart', 'utf8');

const oldSourceBlock = `  String get dataSourceLabel {
    switch (dataSource) {
      case 'app_registration':
        return 'Daftar Aplikasi';
      case 'historical_company':
        return 'Historis Perusahaan';
      case 'manual_admin':
      default:
        return 'Input Manual Admin';
    }
  }`;

const newSourceBlock = `  String get dataSourceLabel {
    switch (dataSource) {
      case 'app_registration':
        return 'Registrasi Mobile App';
      case 'historical_company':
        return 'Kantor Pemasaran (Direct)';
      case 'manual_admin':
      default:
        return 'Kantor Pemasaran (Direct)';
    }
  }`;

const oldVerifBlock = `  String get verificationStatusLabel {
    switch (verificationStatus) {
      case 'verified':
        return 'Terverifikasi';
      case 'pending_verification':
        return 'Menunggu Verifikasi';
      case 'unverified':
      default:
        return 'Belum Diverifikasi';
    }
  }`;

const newVerifBlock = `  String get verificationStatusLabel {
    switch (verificationStatus) {
      case 'verified':
        return 'Data Terverifikasi';
      case 'pending_verification':
        return 'Menunggu Verifikasi';
      case 'unverified':
      default:
        return 'Belum Diverifikasi';
    }
  }`;

// Handle both CRLF and LF
const normalize = (str) => str.replace(/\r\n/g, '\n');
let normContent = normalize(content);

if (normContent.includes(normalize(oldSourceBlock))) {
  normContent = normContent.replace(normalize(oldSourceBlock), normalize(newSourceBlock));
} else {
  console.log('Source block not matched');
}

if (normContent.includes(normalize(oldVerifBlock))) {
  normContent = normContent.replace(normalize(oldVerifBlock), normalize(newVerifBlock));
} else {
  console.log('Verif block not matched');
}

fs.writeFileSync('lib/models/buyer_record_model.dart', normContent.replace(/\n/g, '\r\n'), 'utf8');
console.log('Successfully updated buyer_record_model.dart!');

