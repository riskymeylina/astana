import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const Color _kBrownLight = Color(0xFFFFF0E6);
const Color _kBeige = Color(0xFFF5EDE0);

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerImagePath,
    this.illustrationWidget,
    this.footer,
    this.showBackButton = false,
    this.onBack,
    this.topImageFraction = 0.38,
    this.panelTopFraction = 0.34,
    this.panelRadius = 28.0,
    this.header,
    this.titleAlignment = CrossAxisAlignment.start,
    this.titleTextAlign,
    this.overlayButtonColor,
    this.backgroundColor,
  });

  final String? headerImagePath;
  final Widget? illustrationWidget;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double topImageFraction;
  final double panelTopFraction;
  final double panelRadius;
  final Widget? header;
  final CrossAxisAlignment titleAlignment;
  final TextAlign? titleTextAlign;
  final Color? overlayButtonColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final bool hasImage = headerImagePath != null;
    final bool hasIllustration = illustrationWidget != null;
    final Color bgColor = backgroundColor ?? _kBeige;

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

    if (kIsWeb && size.width >= 900) {
      return _buildDesktopLayout(
        context,
        backgroundColor: bgColor,
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
      );
    }

    Widget topSection;
    if (hasImage) {
      final imgH = height * topImageFraction;
      const panelOverlap = 24.0;
      topSection = SizedBox(
        height: imgH - panelOverlap,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: imgH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    headerImagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF5A2A0D), Color(0xFF8B3E0F)],
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
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.05),
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
      );
    } else if (hasIllustration) {
      final illustH = height * 0.30;
      topSection = Container(
        height: illustH,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBeige, _kBrownLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: showBackButton ? 24.0 : 0),
              Expanded(child: Center(child: illustrationWidget!)),
            ],
          ),
        ),
      );
    } else {
      topSection = const SizedBox.shrink();
    }

    Widget panelContent = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(panelRadius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
          // Drag indicator
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
          if (header != null) ...[header!, const SizedBox(height: 20)],
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: titleAlignment,
              children: [
                Text(title, textAlign: titleTextAlign, style: titleStyle),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: titleTextAlign, style: subtitleStyle),
              ],
            ),
          ),
          const SizedBox(height: 28),
          child,
          if (footer != null) ...[const SizedBox(height: 16), footer!],
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background colour behind the scroll area
          Positioned.fill(child: Container(color: bgColor)),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(children: [topSection, panelContent]),
            ),
          ),
          // Back button overlay
          if (showBackButton)
            Positioned(
              top: 8,
              left: 8,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onBack ?? () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (overlayButtonColor ?? Colors.white).withValues(
                          alpha: 0.92,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: overlayButtonColor == null
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context, {
    required Color backgroundColor,
    required TextStyle? titleStyle,
    required TextStyle? subtitleStyle,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6F3212).withValues(alpha: 0.12),
                      blurRadius: 44,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                        Expanded(
                          flex: 11,
                          child: const _DesktopAuthImagePanel(),
                        ),
                        Expanded(
                          flex: 10,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 44,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showBackButton) ...[
                                  IconButton(
                                    onPressed:
                                        onBack ??
                                        () => Navigator.maybePop(context),
                                    tooltip: 'Kembali',
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFF7F2EC),
                                      foregroundColor: const Color(0xFF4A1F09),
                                    ),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: titleAlignment,
                                    children: [
                                      Text(
                                        title,
                                        textAlign: titleTextAlign,
                                        style: titleStyle?.copyWith(
                                          fontSize: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        subtitle,
                                        textAlign: titleTextAlign,
                                        style: subtitleStyle?.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),
                                child,
                                if (footer != null) ...[
                                  const SizedBox(height: 22),
                                  footer!,
                                ],
                              ],
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

class _DesktopAuthImagePanel extends StatelessWidget {
  const _DesktopAuthImagePanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/prambanan_tipe_65.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A1F09), Color(0xFF8B3E0F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0xAA000000)],
            ),
          ),
        ),
        Positioned(
          left: 32,
          right: 24,
          top: 28,
          child: Row(
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
                      color: Color(0xFF713910),
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'PT. ASTANA KARYA\nBANDAWASA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 36,
          right: 32,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temukan hunian yang tepat untuk masa depan Anda.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hunian berkualitas, investasi masa depan.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
