const fs = require('fs');
let code = fs.readFileSync('lib/screens/auth/login_screen.dart', 'utf8');

const target = "data['message'] ?? 'Email atau Password salah',\n          isError: true,\n        );";
const targetCRLF = "data['message'] ?? 'Email atau Password salah',\r\n          isError: true,\r\n        );";

if (code.includes(target)) {
  code = code.replace(target, target + "\n        _passController.clear();");
  fs.writeFileSync('lib/screens/auth/login_screen.dart', code);
  console.log('SUCCESS ADDING CLEAR (LF)');
} else if (code.includes(targetCRLF)) {
  code = code.replace(targetCRLF, targetCRLF + "\r\n        _passController.clear();");
  fs.writeFileSync('lib/screens/auth/login_screen.dart', code);
  console.log('SUCCESS ADDING CLEAR (CRLF)');
} else {
  console.log('TARGET NOT FOUND');
}

