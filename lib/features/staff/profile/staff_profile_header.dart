import 'package:flutter/material.dart';

import '../../../features/shared/profile/profile_avatar.dart';
import 'staff_profile_controller.dart';

class StaffProfileHeader extends StatelessWidget {
  final StaffProfileController controller;
  final VoidCallback? onEditProfile;
  final VoidCallback? onUploadSuccess;

  const StaffProfileHeader({
    super.key,
    required this.controller,
    this.onEditProfile,
    this.onUploadSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 220,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFB85C1A),
              Color(0xFFD4832E),
              Color(0xFFCB8A3A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative dot grid (left)
            Positioned(
              left: 12,
              bottom: 16,
              child: _DotGrid(),
            ),

            // ── Decorative leaf / organic shape (right)
            Positioned(
              right: -20,
              top: -10,
              child: Opacity(
                opacity: 0.18,
                child: Icon(
                  Icons.eco_rounded,
                  size: 260,
                  color: Colors.white,
                ),
              ),
            ),

            // ── Subtle inner glow overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 28,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // AVATAR
                  _buildAvatar(),

                  const SizedBox(width: 28),

                  // INFO
                  Expanded(child: _buildInfo()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return ProfileAvatar(
      imageUrl: controller.avatarUrl,
      initials: controller.avatarInitials,
      size: 120,
      isEditable: true,
      onUploadSuccess: onUploadSuccess,
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Name + role badge
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.userName,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEditProfile,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 1.5,
                ),
              ),
              child: Text(
                controller.roleLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Thin divider
        Container(
          height: 1,
          width: 320,
          color: Colors.white.withOpacity(0.25),
        ),

        const SizedBox(height: 12),

        // Meta: email | jabatan | departemen
        Wrap(
          spacing: 0,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MetaChip(
              icon: Icons.mail_outline_rounded,
              label: controller.email,
            ),
            _MetaSep(),
            _MetaChip(
              icon: Icons.work_outline_rounded,
              label: controller.jabatan,
            ),
            _MetaSep(),
            _MetaChip(
              icon: Icons.business_outlined,
              label: controller.department,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Dot grid decoration
class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 25,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Meta chip
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetaSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 1,
        height: 14,
        color: Colors.white.withOpacity(0.35),
      ),
    );
  }
}