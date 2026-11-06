import 'package:flutter/material.dart';

/// Reusable brown gradient header widget used across all pages.
///
/// Displays a compact brown gradient box with:
/// - Back arrow button (←)
/// - Title and subtitle text
/// - Decorative background circles
/// - Optional decorative icon on the right
///
/// Usage:
/// ```dart
/// BragaPageHeader(
///   title: 'Kelola Data Properti',
///   subtitle: 'Kelola, pantau, dan perbarui seluruh data properti Anda dengan mudah.',
/// )
/// ```
class BragaPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final IconData? decorativeIcon;
  final List<Widget>? actions;

  const BragaPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.decorativeIcon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF5C1E04), Color(0xFF8F4E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5C1E04).withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle top-right
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Decorative circle bottom-right
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  _BackButton(onBack: onBack),
                  const SizedBox(width: 12),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.72),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Optional action buttons
                  if (actions != null) ...[
                    const SizedBox(width: 8),
                    ...actions!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onBack;

  const _BackButton({this.onBack});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.13),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap:
            onBack ??
            () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
