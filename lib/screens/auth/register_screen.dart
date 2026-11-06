import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'utils/auth_feedback.dart';
import 'widgets/auth_field_label.dart';
import 'widgets/auth_footer_link.dart';
import 'widgets/auth_page_scaffold.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_text_field.dart';

// ─── Brand Palette ───────────────────────────────────────────────────────────
const _brown = Color(0xFF6F3212);
const _brownDark = Color(0xFF4A1F09);
const _brownMid = Color(0xFF8B3E0F);
const _gold = Color(0xFFC78928);
const _cream = Color(0xFFFBF8F5);
const _creamDark = Color(0xFFF5EDE0);
const _textDark = Color(0xFF1A1A1A);
const _textGrey = Color(0xFF7A7A7A);
const _border = Color(0xFFE0D0C0);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isNavigating = false;
  String _selectedRole = 'pembeli';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    debugPrint('[AUTH_DEBUG] Tombol register ditekan');
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passController.text.isEmpty) {
      debugPrint('[AUTH_DEBUG] Validasi lokal gagal: ada field kosong');
      showAuthSnackBar(context, 'Semua field wajib diisi', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('[AUTH_DEBUG] Mengirim request register ke AuthService');
      final response = await _authService.registerUser(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        _passController.text,
        role: _selectedRole,
      );
      debugPrint(
        '[AUTH_DEBUG] Response register diterima: Status Code ${response.statusCode}',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[AUTH_DEBUG] Registrasi sukses');
        if (!mounted) {
          debugPrint(
            '[AUTH_DEBUG] register_screen tidak mounted setelah register',
          );
          return;
        }
        showAuthSnackBar(context, 'Registrasi Berhasil! Selamat datang');
        _isNavigating = true;
        // Admin dan staf diarahkan ke dashboard web
        if (kIsWeb && (_selectedRole == 'admin' || _selectedRole == 'staf')) {
          debugPrint('[AUTH_DEBUG] Navigasi ke /dashboard (web admin/staf)');
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          debugPrint('[AUTH_DEBUG] Navigasi ke /home');
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      var errorMessage = 'Gagal Registrasi';

      if (data['message'] != null) {
        errorMessage = data['message'];
      }

      if (data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        errorMessage = errors.values.first[0];
      }

      debugPrint('[AUTH_DEBUG] Registrasi gagal dengan pesan: $errorMessage');

      if (!mounted) return;
      showAuthSnackBar(
        context,
        errorMessage,
        isError: true,
        duration: const Duration(seconds: 4),
      );
    } catch (e, stackTrace) {
      debugPrint('[AUTH_DEBUG] Catch error saat register: $e\n$stackTrace');
      if (!mounted) return;
      showAuthSnackBar(
        context,
        'Tidak dapat terhubung ke backend. Periksa koneksi atau URL API',
        isError: true,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted && !_isNavigating) {
        setState(() => _isLoading = false);
        debugPrint('[AUTH_DEBUG] State loading di-reset ke false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = kIsWeb && size.width >= 900;
    final isTablet = kIsWeb && size.width >= 600 && size.width < 900;

    if (isDesktop || isTablet) {
      return _DesktopRegisterLayout(
        nameController: _nameController,
        emailController: _emailController,
        phoneController: _phoneController,
        passController: _passController,
        isLoading: _isLoading,
        isPasswordVisible: _isPasswordVisible,
        selectedRole: _selectedRole,
        onTogglePassword: () =>
            setState(() => _isPasswordVisible = !_isPasswordVisible),
        onRoleChanged: (v) => setState(() => _selectedRole = v ?? 'pembeli'),
        onRegister: _register,
        isTablet: isTablet,
      );
    }

    // ── Mobile layout (original design preserved) ──────────────────────────
    return AuthPageScaffold(
      headerImagePath: 'assets/images/1.jpg',
      title: 'Buat Akun Anda',
      subtitle:
          'Selamat datang! Isi data di bawah untuk mulai penjualan properti.',
      showBackButton: true,
      footer: AuthFooterLink(
        prefixText: 'Sudah punya akun? ',
        actionText: 'Masuk',
        onTap: () => Navigator.pushNamed(context, '/login'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthFieldLabel(text: 'Nama Lengkap', isRequired: true),
          const SizedBox(height: 10),
          AuthTextField(
            controller: _nameController,
            borderRadius: 30,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          ),
          const SizedBox(height: 20),
          const AuthFieldLabel(text: 'Alamat Email', isRequired: true),
          const SizedBox(height: 10),
          AuthTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            borderRadius: 30,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          ),
          const SizedBox(height: 20),
          const AuthFieldLabel(text: 'Nomor HP', isRequired: true),
          const SizedBox(height: 10),
          AuthTextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            borderRadius: 30,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          ),
          const SizedBox(height: 20),
          const AuthFieldLabel(text: 'Kata Sandi', isRequired: true),
          const SizedBox(height: 10),
          AuthTextField(
            controller: _passController,
            isPassword: true,
            isPasswordVisible: _isPasswordVisible,
            onTogglePasswordVisibility: () {
              setState(() => _isPasswordVisible = !_isPasswordVisible);
            },
            borderRadius: 30,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          ),
          const SizedBox(height: 40),
          AuthPrimaryButton(
            label: 'Daftar',
            onPressed: _register,
            isLoading: _isLoading,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESKTOP / TABLET LAYOUT (Split-panel mirip login)
// ═══════════════════════════════════════════════════════════════════════════

class _DesktopRegisterLayout extends StatelessWidget {
  const _DesktopRegisterLayout({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passController,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.selectedRole,
    required this.onTogglePassword,
    required this.onRoleChanged,
    required this.onRegister,
    required this.isTablet,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passController;
  final bool isLoading;
  final bool isPasswordVisible;
  final String selectedRole;
  final VoidCallback onTogglePassword;
  final ValueChanged<String?> onRoleChanged;
  final VoidCallback onRegister;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamDark,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 48,
            vertical: 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 780 : 1000,
                minHeight: 580,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _brown.withOpacity(0.12),
                      blurRadius: 48,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── LEFT: Property Image Panel (sama dengan login) ──
                        Expanded(
                          flex: isTablet ? 5 : 11,
                          child: const _RegisterLeftImagePanel(),
                        ),
                        // ── RIGHT: Register Form Panel ───────────────────────
                        Expanded(
                          flex: isTablet ? 6 : 10,
                          child: _RegisterRightFormPanel(
                            nameController: nameController,
                            emailController: emailController,
                            phoneController: phoneController,
                            passController: passController,
                            isLoading: isLoading,
                            isPasswordVisible: isPasswordVisible,
                            selectedRole: selectedRole,
                            onTogglePassword: onTogglePassword,
                            onRoleChanged: onRoleChanged,
                            onRegister: onRegister,
                            onLogin: () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Left Panel (hero image dengan overlay brand) ─────────────────────────────

class _RegisterLeftImagePanel extends StatelessWidget {
  const _RegisterLeftImagePanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Property hero image
        Image.asset(
          'assets/images/prambanan_tipe_65.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Image.asset(
            'assets/images/3.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brownDark, _brownMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        // Dark gradient overlay — bottom heavy
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Color(0x80000000),
                Color(0xCC000000),
              ],
              stops: [0.0, 0.35, 0.70, 1.0],
            ),
          ),
        ),
        // Warm brown tint overlay top-left
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 160,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x996F3212), Colors.transparent],
              ),
            ),
          ),
        ),
        // Content overlaid on image
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo area
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.home_work_rounded,
                          color: _brown,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Astana Karya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                      const Text(
                        'Bandawasa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        height: 1.5,
                        width: 72,
                        color: _gold,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'P R O P E R T Y',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Bottom tagline
              const Text(
                'Bergabunglah\nbersama kami.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Daftarkan akun Anda dan mulai\nperjalanan properti impian bersama kami.',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 14,
                  height: 1.5,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Right Form Panel ─────────────────────────────────────────────────────────

class _RegisterRightFormPanel extends StatelessWidget {
  const _RegisterRightFormPanel({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passController,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.selectedRole,
    required this.onTogglePassword,
    required this.onRoleChanged,
    required this.onRegister,
    required this.onLogin,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passController;
  final bool isLoading;
  final bool isPasswordVisible;
  final String selectedRole;
  final VoidCallback onTogglePassword;
  final ValueChanged<String?> onRoleChanged;
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Buat Akun',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Isi data di bawah untuk mendaftar.',
            style: TextStyle(fontSize: 14, color: _textGrey, height: 1.5),
          ),
          const SizedBox(height: 28),

          // Nama Lengkap
          _WebFieldLabel('Nama Lengkap'),
          const SizedBox(height: 8),
          _WebTextField(
            controller: nameController,
            hint: 'Masukkan nama lengkap',
          ),
          const SizedBox(height: 18),

          // Email
          _WebFieldLabel('Alamat Email'),
          const SizedBox(height: 8),
          _WebTextField(
            controller: emailController,
            hint: 'Masukkan email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),

          // Nomor HP
          _WebFieldLabel('Nomor HP'),
          const SizedBox(height: 8),
          _WebTextField(
            controller: phoneController,
            hint: 'Contoh: 08123456789',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),

          // Kata Sandi
          _WebFieldLabel('Kata Sandi'),
          const SizedBox(height: 8),
          _WebPasswordField(
            controller: passController,
            isVisible: isPasswordVisible,
            onToggle: onTogglePassword,
          ),
          const SizedBox(height: 28),

          // Tombol Daftar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _brown.withOpacity(0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Daftar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Footer link ke login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sudah punya akun? ',
                style: TextStyle(color: _textGrey, fontSize: 13),
              ),
              GestureDetector(
                onTap: onLogin,
                child: const Text(
                  'Masuk',
                  style: TextStyle(
                    color: _brown,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared web field helpers ──────────────────────────────────────────────────

class _WebFieldLabel extends StatelessWidget {
  const _WebFieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textDark,
      ),
    );
  }
}

class _WebTextField extends StatelessWidget {
  const _WebTextField({
    required this.controller,
    this.hint = '',
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textGrey.withOpacity(0.7), fontSize: 14),
        filled: true,
        fillColor: _cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brown, width: 1.5),
        ),
      ),
    );
  }
}

class _WebPasswordField extends StatelessWidget {
  const _WebPasswordField({
    required this.controller,
    required this.isVisible,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool isVisible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(fontSize: 14, color: _textDark),
      decoration: InputDecoration(
        hintText: 'Masukkan kata sandi',
        hintStyle: TextStyle(color: _textGrey.withOpacity(0.7), fontSize: 14),
        filled: true,
        fillColor: _cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brown, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: _textGrey,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
