import 'package:flutter/material.dart';

import '../../../features/shared/profile/profile_setting_tile.dart';

/// Tile khusus logout — tampil di luar container section,
/// dengan label & icon merah sesuai desain.
class BuyerProfileLogoutTile extends StatelessWidget {
  final ProfileSettingTileData item;
  final VoidCallback onTap;

  const BuyerProfileLogoutTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0E4D6)),
          ),
          child: Row(
            children: [
              // Icon container — merah muda
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFD94040),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Label & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD94040),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A7563),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD94040),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
