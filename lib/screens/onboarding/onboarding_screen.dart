import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _brown = Color(0xFF713910);
  static const _brownDark = Color(0xFF4F2E1D);
  static const _canvas = Color(0xFFF9F5EF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 760) {
              return _buildWideLayout(context);
            }
            return _buildCompactLayout(context, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(),
        const _WideImageOverlay(),
        Positioned(top: 28, left: 36, child: _BrandHeader(onImage: true)),
        Align(
          alignment: Alignment.centerRight,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(48, 96, 72, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _buildWelcomeContent(
                context,
                isCompact: false,
                onImage: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, BoxConstraints constraints) {
    final heroHeight = (constraints.maxHeight * 0.43)
        .clamp(240.0, 380.0)
        .toDouble();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(),
                const _ImageOverlay(),
                Positioned(
                  top: 18,
                  left: 20,
                  child: _BrandHeader(onImage: true),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: _buildWelcomeContent(context, isCompact: true),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Image.asset(
      'assets/images/prambanan_tipe_65.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_brownDark, _brown],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeContent(
    BuildContext context, {
    required bool isCompact,
    bool onImage = false,
  }) {
    final titleSize = isCompact ? 38.0 : 52.0;
    final titleColor = onImage ? Colors.white : _brownDark;
    final subtitleColor = onImage
        ? Colors.white.withValues(alpha: 0.94)
        : _brownDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Selamat Datang di',
          style: TextStyle(
            fontFamily: 'TomatoGrotesk',
            color: onImage ? const Color(0xFFFFDFAD) : _brown,
            fontSize: isCompact ? 22 : 28,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Astana Karya\nBandawasa',
          style: TextStyle(
            fontFamily: 'TomatoGrotesk',
            color: titleColor,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 0.98,
            letterSpacing: -1.6,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 96,
          height: 4,
          decoration: BoxDecoration(
            color: _brown,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Temukan hunian impian Anda bersama kami.',
          style: TextStyle(
            fontFamily: 'TomatoGrotesk',
            color: subtitleColor,
            fontSize: isCompact ? 17 : 20,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: isCompact ? double.infinity : 360,
          height: 62,
          child: ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: _brown.withValues(alpha: 0.28),
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Mulai Menjelajahi',
              style: TextStyle(
                fontFamily: 'TomatoGrotesk',
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageOverlay extends StatelessWidget {
  const _ImageOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x30000000), Color(0x00000000), Color(0x38000000)],
        ),
      ),
    );
  }
}

class _WideImageOverlay extends StatelessWidget {
  const _WideImageOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x1A000000), Color(0x08000000), Color(0x99000000)],
          stops: [0, 0.42, 1],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onImage});

  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final textColor = onImage ? Colors.white : OnboardingScreen._brownDark;

    return Row(
      mainAxisSize: MainAxisSize.min,
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
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.apartment_rounded,
                color: OnboardingScreen._brown,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'PT. ASTANA KARYA\nBANDAWASA',
          style: TextStyle(
            fontFamily: 'TomatoGrotesk',
            color: textColor,
            fontSize: 14,
            height: 1.25,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            shadows: onImage
                ? const [
                    Shadow(
                      color: Color(0x88000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
