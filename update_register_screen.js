const fs = require('fs');
let code = fs.readFileSync('lib/screens/auth/register_screen.dart', 'utf8');

// 1. Add _selectedRole in state
code = code.replace(
  '  bool _isNavigating = false;',
  "  bool _isNavigating = false;\n  String _selectedRole = 'pembeli';"
);

// 2. Remove blocking snackbar in _register and pass role
code = code.replace(
  "    if (mounted) {\n      showAuthSnackBar(context, 'Tombol register ditekan! Memvalidasi...');\n    }",
  ""
);

code = code.replace(
  `      final response = await _authService.registerUser(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        _passController.text,
      );`,
  `      final response = await _authService.registerUser(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        _passController.text,
        role: _selectedRole,
      );`
);

// 3. In build, add role dropdown / selector before Kata Sandi
const targetField = "          const AuthFieldLabel(text: 'Kata Sandi', isRequired: true);";
const replacementField = `          const AuthFieldLabel(text: 'Daftar Sebagai (Peran)', isRequired: true),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE0D0C0), width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                isExpanded: true,
                dropdownColor: const Color(0xFFFBF8F5),
                borderRadius: BorderRadius.circular(20),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                items: const [
                  DropdownMenuItem(value: 'pembeli', child: Text('Pembeli / Calon Pembeli')),
                  DropdownMenuItem(value: 'staf', child: Text('Staf Marketing / Operasional')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const AuthFieldLabel(text: 'Kata Sandi', isRequired: true);`;

code = code.replace(targetField, replacementField);

fs.writeFileSync('lib/screens/auth/register_screen.dart', code);
console.log('SUCCESS UPDATING register_screen.dart');

