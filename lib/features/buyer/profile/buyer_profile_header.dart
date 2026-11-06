import 'package:flutter/material.dart';

import '../../../features/shared/profile/profile_info_card.dart';
import 'buyer_profile_controller.dart';

class BuyerProfileHeader extends StatelessWidget {
  final BuyerProfileController controller;
  final VoidCallback? onUploadSuccess;

  const BuyerProfileHeader({
    super.key,
    required this.controller,
    this.onUploadSuccess,
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
      isEditable: true,
      onUploadSuccess: onUploadSuccess,
    );
  }
}