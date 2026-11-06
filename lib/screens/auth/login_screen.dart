import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'utils/auth_feedback.dart';
import 'widgets/auth_field_label.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/login_social_button.dart';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isNavigating = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    debugPrint('[AUTH_DEBUG] Tombol login ditekan');
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      debugPrint(
        '[AUTH_DEBUG] Validasi lokal gagal: email atau password kosong',
      );
      showAuthSnackBar(
        context,
        'Email dan Password wajib diisi',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('[AUTH_DEBUG] Mengirim request login ke AuthService');
      final response = await _authService.loginUser(
        _emailController.text.trim(),
        _passController.text,
      );
      debugPrint(
        '[AUTH_DEBUG] Response login diterima: Status Code ${response.statusCode}',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userName = data['user']?['name'] ?? 'Pengguna';
        final userRole = (data['user']?['role'] ?? 'pembeli')
            .toString()
            .toLowerCase();
        debugPrint(
          '[AUTH_DEBUG] Login sukses untuk user: $userName ($userRole)',
        );

        if (!mounted) {
          debugPrint('[AUTH_DEBUG] login_screen tidak mounted setelah login');
          return;
        }

        if (userRole == 'admin') {
          showAuthSnackBar(context, 'Selamat Datang di Web Admin, $userName!');
        } else if (userRole == 'staf' ||
            userRole == 'staff' ||
            userRole == 'marketing') {
          showAuthSnackBar(
            context,
            'Selamat Datang di Dashboard Staf, $userName!',
          );
        } else {
          showAuthSnackBar(context, 'Selamat Datang, $userName!');
        }

        _isNavigating = true;
        // Admin dan staf diarahkan langsung ke web dashboard
        if (kIsWeb &&
            (userRole == 'admin' ||
                userRole == 'staf' ||
                userRole == 'staff' ||
                userRole == 'marketing')) {
          debugPrint('[AUTH_DEBUG] Navigasi ke /dashboard (web admin/staf)');
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          debugPrint('[AUTH_DEBUG] Navigasi ke /home');
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        debugPrint('[AUTH_DEBUG] Login gagal dengan pesan: ${data['message']}');
        if (!mounted) return;
        showAuthSnackBar(
          context,
          data['message'] ?? 'Email atau Password salah',
          isError: true,
        );
        _passController.clear();
      }
    } catch (e, stackTrace) {
      debugPrint('[AUTH_DEBUG] Catch error saat login: $e\n$stackTrace');
      if (!mounted) return;
      showAuthSnackBar(
        context,
        'Koneksi gagal. Pastikan backend Express berjalan',
        isError: true,
      );
    } finally {
      if (mounted && !_isNavigating) {
        setState(() => _isLoading = false);
        debugPrint('[AUTH_DEBUG] State loading di-reset ke false');
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    final providerLower = provider.toLowerCase();
    final defaultEmail = providerLower == 'google'
        ? 'user.google@gmail.com'
        : 'user.facebook@meta.com';
    final defaultName = providerLower == 'google'
        ? 'Google User'
        : 'Facebook User';
    final defaultProviderId = providerLower == 'google'
        ? 'gid_${DateTime.now().millisecondsSinceEpoch}'
        : 'fbid_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _isLoading = true);
    showAuthSnackBar(context, 'Menghubungkan ke $provider...');

    try {
      final response = await _authService.socialLoginUser(
        provider: providerLower,
        email: defaultEmail,
        name: defaultName,
        providerId: defaultProviderId,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userName = data['user']?['name'] ?? defaultName;
        final userRole = (data['user']?['role'] ?? 'pembeli')
            .toString()
            .toLowerCase();

        if (!mounted) return;

        if (userRole == 'admin') {
          showAuthSnackBar(context, 'Selamat Datang di Web Admin, $userName!');
        } else if (userRole == 'staf' ||
            userRole == 'staff' ||
            userRole == 'marketing') {
          showAuthSnackBar(
            context,
            'Selamat Datang di Dashboard Staf, $userName!',
          );
        } else {
          showAuthSnackBar(context, 'Selamat Datang, $userName!');
        }

        _isNavigating = true;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (!mounted) return;
        showAuthSnackBar(
          context,
          data['message'] ?? 'Gagal login dengan $provider',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[AUTH_DEBUG] Catch error saat social login: $e\n$stackTrace');
      if (!mounted) return;
      showAuthSnackBar(
        context,
        'Koneksi gagal. Pastikan backend Express berjalan',
        isError: true,
      );
    } finally {
      if (mounted && !_isNavigating) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final isTablet = size.width >= 600 && size.width < 900;

    if (isDesktop || isTablet) {
      return _DesktopLoginLayout(
        emailController: _emailController,
        passController: _passController,
        isLoading: _isLoading,
        isPasswordVisible: _isPasswordVisible,
        onTogglePassword: () =>
            setState(() => _isPasswordVisible = !_isPasswordVisible),
        onLogin: _login,
        onSocialLogin: _handleSocialLogin,
        onForgot: () => Navigator.pushNamed(context, '/forgot'),
        onRegister: () => Navigator.pushNamed(context, '/register'),
        isTablet: isTablet,
      );
    }

    // ── Mobile layout (original design preserved) ──────────────────────────
    return _MobileLoginLayout(
      emailController: _emailController,
      passController: _passController,
      isLoading: _isLoading,
      isPasswordVisible: _isPasswordVisible,
      onTogglePassword: () =>
          setState(() => _isPasswordVisible = !_isPasswordVisible),
      onLogin: _login,
      onSocialLogin: _handleSocialLogin,
      onForgot: () => Navigator.pushNamed(context, '/forgot'),
      onRegister: () => Navigator.pushNamed(context, '/register'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESKTOP / TABLET LAYOUT
// ═══════════════════════════════════════════════════════════════════════════

class _DesktopLoginLayout extends StatelessWidget {
  const _DesktopLoginLayout({
    required this.emailController,
    required this.passController,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onSocialLogin,
    required this.onForgot,
    required this.onRegister,
    required this.isTablet,
  });

  final TextEditingController emailController;
  final TextEditingController passController;
  final bool isLoading;
  final bool isPasswordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final Future<void> Function(String) onSocialLogin;
  final VoidCallback onForgot;
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
                minHeight: 520,
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
                        // ── LEFT: Property Image Panel ──────────────────
                        Expanded(
                          flex: isTablet ? 5 : 11,
                          child: const _LeftImagePanel(),
                        ),
                        // ── RIGHT: Login Form Panel ─────────────────────
                        Expanded(
                          flex: isTablet ? 6 : 10,
                          child: _RightFormPanel(
                            emailController: emailController,
                            passController: passController,
                            isLoading: isLoading,
                            isPasswordVisible: isPasswordVisible,
                            onTogglePassword: onTogglePassword,
                            onLogin: onLogin,
                            onSocialLogin: onSocialLogin,
                            onForgot: onForgot,
                            onRegister: onRegister,
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

// ── Left Panel ───────────────────────────────────────────────────────────────

class _LeftImagePanel extends StatelessWidget {
  const _LeftImagePanel();

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
              // Welcome text at bottom
              const Text(
                'Selamat Datang di',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Astana Karya\nBandawasa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: 0.3,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(width: 32, height: 2.5, color: _gold),
                  const SizedBox(width: 8),
                  const Text(
                    'Temukan hunian impian Anda\nbersama kami.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Right Form Panel ─────────────────────────────────────────────────────────

class _RightFormPanel extends StatelessWidget {
  const _RightFormPanel({
    required this.emailController,
    required this.passController,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onSocialLogin,
    required this.onForgot,
    required this.onRegister,
  });

  final TextEditingController emailController;
  final TextEditingController passController;
  final bool isLoading;
  final bool isPasswordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final Future<void> Function(String) onSocialLogin;
  final VoidCallback onForgot;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header
          const Text(
            'Masuk ke Akun\nPenjualan Properti',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _textDark,
              height: 1.2,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selamat datang kembali! Kelola penjualan properti\nAnda dengan mudah.',
            style: TextStyle(fontSize: 13.5, color: _textGrey, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Email field
          _DesktopFieldLabel(text: 'Alamat Email', isRequired: true),
          const SizedBox(height: 8),
          AuthTextField(
            controller: emailController,
            hintText: 'Masukkan email Anda',
            keyboardType: TextInputType.emailAddress,
            borderRadius: 30,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          ),
          const SizedBox(height: 20),

          // Password field
          _DesktopFieldLabel(text: 'Kata Sandi', isRequired: true),
          const SizedBox(height: 8),
          AuthTextField(
            controller: passController,
            hintText: 'Masukkan kata sandi',
            isPassword: true,
            isPasswordVisible: isPasswordVisible,
            onTogglePasswordVisibility: onTogglePassword,
            borderRadius: 30,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          ),

          // Lupa kata sandi
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgot,
              style: TextButton.styleFrom(
                foregroundColor: _brownMid,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              child: const Text(
                'Lupa Kata Sandi?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _brownMid,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tombol Masuk
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _brown.withOpacity(0.6),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Divider "atau masuk dengan"
          Row(
            children: [
              Expanded(
                child: Divider(color: Colors.grey.shade200, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'atau masuk dengan',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
              Expanded(
                child: Divider(color: Colors.grey.shade200, thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Social buttons
          Row(
            children: [
              LoginSocialButton(
                assetPath: 'assets/images/google.png',
                label: 'Google',
                onTap: () => onSocialLogin('Google'),
              ),
              const SizedBox(width: 12),
              LoginSocialButton(
                assetPath: 'assets/images/facebook.png',
                label: 'Facebook',
                onTap: () => onSocialLogin('Facebook'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Daftar
          Center(
            child: RichText(
              text: TextSpan(
                text: 'Belum punya akun? ',
                style: const TextStyle(fontSize: 13.5, color: _textGrey),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: onRegister,
                      child: const Text(
                        'Daftar sekarang',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _brownMid,
                          decoration: TextDecoration.underline,
                          decorationColor: _brownMid,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop field helpers ─────────────────────────────────────────────────────

class _DesktopFieldLabel extends StatelessWidget {
  const _DesktopFieldLabel({required this.text, this.isRequired = false});
  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: _textDark,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]
            : [],
      ),
    );
  }
}

class _DesktopTextField extends StatelessWidget {
  const _DesktopTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      style: const TextStyle(fontSize: 14, color: _textDark),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade400),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(prefixIcon, size: 20, color: Colors.grey.shade400),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
                onPressed: onTogglePassword,
                splashRadius: 20,
              )
            : null,
        filled: true,
        fillColor: _cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brownMid, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOBILE LAYOUT  (original design — untouched logic, restored visuals)
// ═══════════════════════════════════════════════════════════════════════════

class _MobileLoginLayout extends StatelessWidget {
  const _MobileLoginLayout({
    required this.emailController,
    required this.passController,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onSocialLogin,
    required this.onForgot,
    required this.onRegister,
  });

  final TextEditingController emailController;
  final TextEditingController passController;
  final bool isLoading;
  final bool isPasswordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final Future<void> Function(String) onSocialLogin;
  final VoidCallback onForgot;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const bgColor = Color(0xFFF5EDE0);

    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1A1A1A),
      fontSize: 26,
      height: 1.2,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF7A7A7A),
      fontSize: 14,
      height: 1.5,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: bgColor)),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Header image
                  SizedBox(
                    height: size.height * 0.38 - 24,
                    width: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: size.height * 0.38,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/3.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF5A2A0D),
                                        Color(0xFF8B3E0F),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.15),
                                      Colors.black.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Panel
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          'Masuk ke Akun Penjualan Properti',
                          style: titleStyle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Selamat datang kembali! Kelola penjualan properti Anda dengan mudah.',
                          style: subtitleStyle,
                        ),
                        const SizedBox(height: 28),
                        // Form fields (use existing widgets via import)
                        _MobileFormContent(
                          emailController: emailController,
                          passController: passController,
                          isLoading: isLoading,
                          isPasswordVisible: isPasswordVisible,
                          onTogglePassword: onTogglePassword,
                          onLogin: onLogin,
                          onSocialLogin: onSocialLogin,
                          onForgot: onForgot,
                          onRegister: onRegister,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileFormContent extends StatelessWidget {
  const _MobileFormContent({
    required this.emailController,
    required this.passController,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onSocialLogin,
    required this.onForgot,
    required this.onRegister,
  });

  final TextEditingController emailController;
  final TextEditingController passController;
  final bool isLoading;
  final bool isPasswordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final Future<void> Function(String) onSocialLogin;
  final VoidCallback onForgot;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    // Reuse desktop field widgets for consistent styling
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthFieldLabel(text: 'Alamat Email', isRequired: true),
        const SizedBox(height: 10),
        AuthTextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
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
          controller: passController,
          isPassword: true,
          isPasswordVisible: isPasswordVisible,
          onTogglePasswordVisibility: onTogglePassword,
          borderRadius: 30,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgot,
            child: const Text(
              'Lupa Kata Sandi?',
              style: TextStyle(
                color: _brownMid,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _brown.withOpacity(0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Masuk',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'atau masuk dengan',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            LoginSocialButton(
              assetPath: 'assets/images/google.png',
              label: 'Google',
              onTap: () => onSocialLogin('Google'),
            ),
            const SizedBox(width: 12),
            LoginSocialButton(
              assetPath: 'assets/images/facebook.png',
              label: 'Facebook',
              onTap: () => onSocialLogin('Facebook'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            text: TextSpan(
              text: 'Belum punya akun? ',
              style: const TextStyle(fontSize: 13.5, color: _textGrey),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: onRegister,
                    child: const Text(
                      'Daftar sekarang',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _brownMid,
                        decoration: TextDecoration.underline,
                        decorationColor: _brownMid,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }
}
