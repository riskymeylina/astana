import 'package:flutter/material.dart';

import '../../../models/buyer_address_model.dart';
import '../../../models/buyer_contact_model.dart';
import '../../../services/buyer_profile_service.dart';

// ════════════════════════════════════════════════════════════════════════════
//  BuyerAdministrationPage
//  Path: features/buyer/profile/buyer_administration_page.dart
// ════════════════════════════════════════════════════════════════════════════

class BuyerAdministrationPage extends StatefulWidget {
  const BuyerAdministrationPage({super.key});

  @override
  State<BuyerAdministrationPage> createState() =>
      _BuyerAdministrationPageState();
}

class _BuyerAdministrationPageState extends State<BuyerAdministrationPage> {
  final BuyerProfileService _profileService = BuyerProfileService();

  // ── state ─────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // ── controllers : DATA PRIBADI ────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // ── controllers : ALAMAT ──────────────────────────────────────────────────
  final _recipientCtrl = TextEditingController();
  final _addressLineCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _subdistrictCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _waCtrl,
      _noteCtrl,
      _recipientCtrl,
      _addressLineCtrl,
      _provinceCtrl,
      _cityCtrl,
      _districtCtrl,
      _subdistrictCtrl,
      _postalCodeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── load ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _profileService.getMyBuyerProfile();
    if (!mounted) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      setState(() {
        _errorMessage = _profileService.parseMessage(response.body);
        _isLoading = false;
      });
      return;
    }

    final profile = _profileService.parseProfile(response.body);
    _fillControllers(profile);
    setState(() => _isLoading = false);
  }

  void _fillControllers(BuyerProfileData profile) {
    final name = profile.user?['name']?.toString() ?? '';
    _nameCtrl.text = name;
    _emailCtrl.text = profile.contact.email;
    _phoneCtrl.text = profile.contact.phone;
    _waCtrl.text = profile.contact.whatsapp;
    _noteCtrl.text = profile.contact.contactNote;

    _recipientCtrl.text = profile.address.recipientName.isNotEmpty
        ? profile.address.recipientName
        : name;
    _addressLineCtrl.text = profile.address.addressLine;
    _provinceCtrl.text = profile.address.province;
    _cityCtrl.text = profile.address.city;
    _districtCtrl.text = profile.address.district;
    _subdistrictCtrl.text = profile.address.subdistrict;
    _postalCodeCtrl.text = profile.address.postalCode;
  }

  // ── save ──────────────────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final contact = BuyerContactModel(
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      whatsapp: _waCtrl.text.trim(),
      contactNote: _noteCtrl.text.trim(),
    );

    final address = BuyerAddressModel(
      recipientName: _recipientCtrl.text.trim(),
      addressLine: _addressLineCtrl.text.trim(),
      province: _provinceCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      subdistrict: _subdistrictCtrl.text.trim(),
      postalCode: _postalCodeCtrl.text.trim(),
      landmark: '',
    );

    final response = await _profileService.updateMyBuyerProfile(
      contact: contact,
      address: address,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_profileService.parseMessage(response.body)),
          backgroundColor: const Color(0xFFD94040),
        ),
      );
      return;
    }

    await _profileService.syncSessionUserFromResponse(response.body);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perubahan berhasil disimpan'),
        backgroundColor: Color(0xFF4A7C59),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E8),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _loadProfile)
          : _buildForm(),
      bottomNavigationBar: (_isLoading || _errorMessage != null)
          ? null
          : _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF6B2D0E),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Detail Pribadi',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            'Kelola informasi pribadi, kontak, dan alamat Anda',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFEED8C4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      titleSpacing: 0,
    );
  }

  Widget _buildForm() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Banner keamanan ────────────────────────────────────────────
          const _SecurityBanner(),
          const SizedBox(height: 24),

          // ── DATA PRIBADI ───────────────────────────────────────────────
          const _SectionLabel(label: 'DATA PRIBADI'),
          const SizedBox(height: 10),
          _FieldCard(
            icon: Icons.person_outline_rounded,
            label: 'Nama Lengkap',
            controller: _nameCtrl,
          ),
          _FieldCard(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          _FieldCard(
            icon: Icons.edit_outlined,
            label: 'Nomor HP',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 24),

          // ── ALAMAT ────────────────────────────────────────────────────
          const _SectionLabel(label: 'ALAMAT'),
          const SizedBox(height: 10),
          _FieldCard(
            icon: Icons.person_outline_rounded,
            label: 'Nama Penerima',
            controller: _recipientCtrl,
          ),
          _FieldCard(
            icon: Icons.home_outlined,
            label: 'Alamat Lengkap',
            controller: _addressLineCtrl,
            maxLines: 2,
          ),

          // Provinsi & Kota — 2 kolom
          Row(
            children: [
              Expanded(
                child: _FieldCard(
                  icon: Icons.map_outlined,
                  label: 'Provinsi',
                  controller: _provinceCtrl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FieldCard(
                  icon: Icons.apartment_outlined,
                  label: 'Kota / Kabupaten',
                  controller: _cityCtrl,
                ),
              ),
            ],
          ),

          // Kecamatan & Kelurahan — 2 kolom
          Row(
            children: [
              Expanded(
                child: _FieldCard(
                  icon: Icons.location_on_outlined,
                  label: 'Kecamatan',
                  controller: _districtCtrl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FieldCard(
                  icon: Icons.flag_outlined,
                  label: 'Kelurahan / Desa',
                  controller: _subdistrictCtrl,
                ),
              ),
            ],
          ),

          _FieldCard(
            icon: Icons.mail_outline_rounded,
            label: 'Kode Pos',
            controller: _postalCodeCtrl,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6B2D0E),
              disabledBackgroundColor: const Color(
                0xFF6B2D0E,
              ).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Private sub-widgets
// ════════════════════════════════════════════════════════════════════════════

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDD9B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE2B8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF7A3B0A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Anda aman',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF2F2318),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Kami menjaga keamanan data pribadi Anda sesuai dengan kebijakan privasi kami.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A6552),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF8A7563),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: Color(0xFF8A6F4D),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? hint;
  final int maxLines;

  const _FieldCard({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  }) : hint = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7D5BF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF9C836A)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F2318),
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9C836A),
                  fontWeight: FontWeight.w500,
                ),
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFBEAC98),
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFF8F4E1E),
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat profil',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F2318),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A6552)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6B2D0E),
              ),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
