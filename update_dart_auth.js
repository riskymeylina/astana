const fs = require('fs');
let code = fs.readFileSync('lib/services/auth_service.dart', 'utf8');

const isCrlf = code.includes('\r\n');
const lines = code.split(/\r?\n/);

const idx = lines.findIndex(l => l.includes('Future<ApiResponse> registerUser('));
if (idx !== -1) {
  // Let's inspect next 35 lines
  console.log('Found registerUser at line', idx + 1);
  // Replace the signature and body up to timeout
  const endIdx = lines.findIndex((l, i) => i > idx && l.includes('.timeout(_requestTimeout);'));
  console.log('Found timeout at line', endIdx + 1);

  const newBlock = [
    '  Future<ApiResponse> registerUser(',
    '    String name,',
    '    String email,',
    '    String phone,',
    '    String password, {',
    "    String role = 'pembeli',",
    '  }) async {',
    "    debugPrint('[AUTH_DEBUG] registerUser dipanggil untuk: $email (role: $role)');",
    '    if (name.trim().isEmpty ||',
    '        email.trim().isEmpty ||',
    '        phone.trim().isEmpty ||',
    '        password.isEmpty) {',
    "      debugPrint('[AUTH_DEBUG] registerUser gagal: ada field kosong');",
    '      return ApiResponse(',
    '        statusCode: 400,',
    "        body: jsonEncode({'message': 'Semua field wajib diisi'}),",
    '      );',
    '    }',
    '',
    '    try {',
    "      final url = '$_apiBaseUrl/register';",
    "      debugPrint('[AUTH_DEBUG] Mengirim POST request ke $url');",
    '      final response = await http',
    '          .post(',
    '            Uri.parse(url),',
    "            headers: {'Content-Type': 'application/json'},",
    '            body: jsonEncode({',
    "              'name': name.trim(),",
    "              'email': email.trim(),",
    "              'phone': phone.trim(),",
    "              'password': password,",
    "              'role': role,",
    '            }),',
    '          )',
    '          .timeout(_requestTimeout);'
  ];

  lines.splice(idx, endIdx - idx + 1, ...newBlock);
  fs.writeFileSync('lib/services/auth_service.dart', lines.join(isCrlf ? '\r\n' : '\n'));
  console.log('SUCCESSFULLY REPLACED registerUser in auth_service.dart');
} else {
  console.log('registerUser NOT FOUND');
}

