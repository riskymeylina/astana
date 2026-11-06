import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/consultation_service.dart';
import '../../widgets/bottom_nav_section.dart';
import '../../widgets/braga_page_header.dart';

const Color _consultationCream = Color(0xFFFDD096);
const Color _consultationBrown = Color(0xFF8B4F1F);
const Color _consultationDeepBrown = Color(0xFF5E3210);
const Color _consultationInk = Color(0xFF2E2A26);
const Color _consultationSurface = Color(0xFFFFFBF6);

class ConsultationPage extends StatefulWidget {
  final int? propertyId;
  final String? propertyTitle;

  const ConsultationPage({super.key, this.propertyId, this.propertyTitle});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _messageController = TextEditingController();

  String _selectedTopic = 'Cari rumah sesuai budget';
  String _selectedContactMethod = 'WhatsApp';
  bool _isSubmitting = false;

  static const List<String> _topics = [
    'Cari rumah sesuai budget',
    'Beli rumah pertama',
    'Cek legal & dokumen',
    'Simulasi Cicilan Langsung',
    'Lokasi strategis',
  ];

  static const List<String> _contactMethods = ['WhatsApp', 'Telepon', 'Email'];

  @override
  void initState() {
    super.initState();
    if (widget.propertyTitle != null) {
      _messageController.text =
          'Saya ingin konsultasi tentang ${widget.propertyTitle}.';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitConsultation() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan konsultasi wajib diisi')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final response = await _consultationService.createConsultationRequest(
      propertyId: widget.propertyId,
      topic: _selectedTopic,
      preferredContactMethod: _selectedContactMethod,
      message: message,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(_consultationService.parseMessage(response.body))),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      Navigator.pushReplacementNamed(context, '/buyer-consultation-requests');
    }
  }

  void _openSurveyEntry() {
    if (widget.propertyId != null) {
      Navigator.pushNamed(
        context,
        '/survey-form',
        arguments: {
          'propertyId': widget.propertyId!,
          'propertyTitle': widget.propertyTitle ?? 'Properti pilihan',
        },
      );
      return;
    }

    Navigator.pushNamed(context, '/buyer-survey-requests');
  }

  void _handleBottomNavTap(int index) {
    if (index == 3) return;

    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {'selectedIndex': index},
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _consultationSurface,
      bottomNavigationBar: BottomNavSection(
        currentIndex: 3,
        onTap: _handleBottomNavTap,
      ),
      body: Stack(
        children: [
          const _BackgroundDecor(),
          Column(
            children: [
              const BragaPageHeader(
                title: 'Konsultasi Properti',
                subtitle: 'Tim kami siap membantu Anda.',
                decorativeIcon: Icons.forum_rounded,
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroCard(propertyTitle: widget.propertyTitle),
                        const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Topik untuk Calon Pembeli',
                    subtitle:
                        'Pilih topik utama agar tim pemasaran bisa menyiapkan tindak lanjut yang tepat.',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final topic in _topics)
                          _ChoicePill(
                            label: topic,
                            selected: _selectedTopic == topic,
                            onTap: () => setState(() => _selectedTopic = topic),
                          ),
                        _ChoicePill(
                          label: 'Survey lokasi',
                          selected: false,
                          onTap: _openSurveyEntry,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Metode Kontak',
                    subtitle:
                        'Pilih kanal yang paling mudah untuk dihubungi staf.',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final method in _contactMethods)
                          _ChoicePill(
                            label: method,
                            selected: _selectedContactMethod == method,
                            onTap: () =>
                                setState(() => _selectedContactMethod = method),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Detail Kebutuhan',
                    subtitle: widget.propertyTitle == null
                        ? 'Ceritakan kebutuhan properti, budget, lokasi, atau pertanyaan legalitas Anda.'
                        : 'Konsultasi ini akan terhubung dengan properti pilihan Anda.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.propertyTitle != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3DF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFEAC790),
                              ),
                            ),
                            child: Text(
                              widget.propertyTitle!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _consultationDeepBrown,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _messageController,
                          minLines: 5,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText:
                                'Contoh: Saya ingin mengetahui skema cicilan langsung dari perusahaan.',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFFE9D7BF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: _consultationCream,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitConsultation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _consultationCream,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Ajukan Konsultasi',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                        _SectionCard(
                          title: 'Topik untuk Calon Pembeli',
                          subtitle:
                              'Pilih topik utama agar tim pemasaran bisa menyiapkan tindak lanjut yang tepat.',
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final topic in _topics)
                                _ChoicePill(
                                  label: topic,
                                  selected: _selectedTopic == topic,
                                  onTap: () => setState(() => _selectedTopic = topic),
                                ),
                              _ChoicePill(
                                label: 'Survey lokasi',
                                selected: false,
                                onTap: _openSurveyEntry,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'Metode Kontak',
                          subtitle:
                              'Pilih kanal yang paling mudah untuk dihubungi staf.',
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final method in _contactMethods)
                                _ChoicePill(
                                  label: method,
                                  selected: _selectedContactMethod == method,
                                  onTap: () =>
                                      setState(() => _selectedContactMethod = method),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'Detail Kebutuhan',
                          subtitle: widget.propertyTitle == null
                              ? 'Ceritakan kebutuhan properti, budget, lokasi, atau pertanyaan legalitas Anda.'
                              : 'Konsultasi ini akan terhubung dengan properti pilihan Anda.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.propertyTitle != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3DF),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFEAC790),
                                    ),
                                  ),
                                  child: Text(
                                    widget.propertyTitle!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _consultationDeepBrown,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextField(
                                controller: _messageController,
                                minLines: 5,
                                maxLines: 8,
                                decoration: InputDecoration(
                                  hintText:
                                      'Contoh: Saya ingin mengetahui skema cicilan langsung dari perusahaan.',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE9D7BF),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: const BorderSide(
                                      color: _consultationCream,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitConsultation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _consultationCream,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'Ajukan Konsultasi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/buyer-consultation-requests',
                          ),
                          child: const Text('Lihat permintaan konsultasi saya'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF8EF), Color(0xFFFFFCFA), Color(0xFFF8F2EA)],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String? propertyTitle;

  const _HeroCard({required this.propertyTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B4F1F), Color(0xFF5E3210)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x228B4F1F),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.forum_rounded, color: _consultationCream, size: 34),
          const SizedBox(height: 18),
          Text(
            propertyTitle == null
                ? 'Tim konsultasi siap bantu'
                : 'Konsultasi properti pilihan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            propertyTitle == null
                ? 'Ajukan kebutuhan pembelian, legalitas, lokasi, atau informasi cicilan langsung perusahaan.'
                : 'Ajukan pertanyaan khusus untuk $propertyTitle dan tim akan menindaklanjuti dari dashboard.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D7BF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _consultationInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF7A6552), height: 1.4),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _consultationBrown : const Color(0xFFFFF7EC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _consultationBrown : const Color(0xFFE9D7BF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _consultationDeepBrown,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
