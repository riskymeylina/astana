import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import 'buyer_profile_controller.dart';
import 'buyer_profile_header.dart';
import 'buyer_profile_menu.dart';
import 'buyer_profile_logout_tile.dart';

class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({super.key});

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  final controller = BuyerProfileController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil Saya',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2F2318),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Kelola akun dan aktivitas pembelian Anda.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8A7563),
                  height: 1.4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          BuyerProfileHeader(
            controller: controller,
            onUploadSuccess: () => setState(() {}),
          ),

          const SizedBox(height: 16),
          BuyerProfileMenu(section: controller.sections[0]),

          const SizedBox(height: 14),
          BuyerProfileMenu(section: controller.sections[1]),

          const SizedBox(height: 16),
          BuyerProfileLogoutTile(
            item: BuyerProfileController.logoutItem,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    await AuthService().clearSession();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
