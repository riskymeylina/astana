import 'package:flutter/material.dart';

import '../../../features/shared/profile/profile_info_card.dart';
import 'admin_profile_controller.dart';

class AdminProfileHeader extends StatelessWidget {
  final AdminProfileController controller;

  const AdminProfileHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileInfoCard(
      avatarUrl: controller.avatarUrl,
      initials: controller.avatarInitials,
      userName: controller.userName,
      email: controller.email,
      roleLabel: controller.roleLabel,
      statusLabel: controller.accountStatus,
    );
  }
}
