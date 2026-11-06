const fs = require('fs');
let code = fs.readFileSync('src/controllers/authController.js', 'utf8');
const searchStr = "authService.registerUser({\r\n      name: req.body.name.trim(),\r\n      email: normalizeEmail(req.body.email),\r\n      phone: req.body.phone.trim(),\r\n      password: req.body.password,\r\n    })";
const searchStrUnix = "authService.registerUser({\n      name: req.body.name.trim(),\n      email: normalizeEmail(req.body.email),\n      phone: req.body.phone.trim(),\n      password: req.body.password,\n    })";

const replaceStr = "authService.registerUser({\n      name: req.body.name.trim(),\n      email: normalizeEmail(req.body.email),\n      phone: req.body.phone.trim(),\n      password: req.body.password,\n      role: ['pembeli', 'staf', 'admin'].includes((req.body.role || '').toLowerCase().trim()) ? (req.body.role || '').toLowerCase().trim() : 'pembeli',\n    })";

if (code.includes(searchStr)) {
  code = code.replace(searchStr, replaceStr);
  fs.writeFileSync('src/controllers/authController.js', code);
  console.log('REPLACED CRLF');
} else if (code.includes(searchStrUnix)) {
  code = code.replace(searchStrUnix, replaceStr);
  fs.writeFileSync('src/controllers/authController.js', code);
  console.log('REPLACED LF');
} else {
  console.log('NEITHER MATCHED');
}
