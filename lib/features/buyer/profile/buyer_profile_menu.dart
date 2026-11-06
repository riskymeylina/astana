import 'package:flutter/material.dart';

import '../../../features/shared/profile/profile_section_title.dart';
import '../../../features/shared/profile/profile_setting_tile.dart';

class BuyerProfileMenu extends StatelessWidget {
  final ProfileSectionData section;

  const BuyerProfileMenu({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E4D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title: section.title),
          const SizedBox(height: 6),
          ...section.items.map(
            (item) => Column(
              children: [
                ProfileSettingTile(item: item),
                if (item != section.items.last)
                  const Divider(
                    height: 1,
                    color: Color(0xFFF3ECE4),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}