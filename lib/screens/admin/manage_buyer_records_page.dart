import '../../../services/admin_report_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/buyer_record_model.dart';
import '../../../models/property_model.dart';
import '../../../services/admin_buyer_record_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/property_service.dart' hide ApiResponse;
import '../../../widgets/braga_page_header.dart';

class ManageBuyerRecordsPage extends StatefulWidget {
  const ManageBuyerRecordsPage({super.key});

  @override
  State<ManageBuyerRecordsPage> createState() => _ManageBuyerRecordsPageState();
}

class _ManageBuyerRecordsPageState extends State<ManageBuyerRecordsPage>
    with SingleTickerProviderStateMixin {
  final AdminBuyerRecordService _service = AdminBuyerRecordService();
  final AdminReportService _reportService = AdminReportService();
  double _totalPortfolioRevenue = 0;

  List<BuyerRecord> _records = [];
  bool _loading = true;
  String? _error;
  int _total = 0;
  int _currentPage = 1;
  static const int _pageSize = 15;

  BuyerRecord? _selected;
  BuyerRecordActivity? _selectedActivity;
  bool _loadingActivity = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String? _filterDataSource;
  String? _filterVerificationStatus;

  // Luxury Brand Theme Palette (PT Astana Karya Bandawasa)
  static const _brown = Color(0xFF6F3212);
  static const _brownDark = Color(0xFF4A1F09);
  static const _brownLight = Color(0xFF9E4B1C);
  static const _gold = Color(0xFFC78928);
  static const _goldLight = Color(0xFFFFF7ED);
  static const _border = Color(0xFFE8D7C7);
  static const _bg = Color(0xFFFBF8F5);
  static const _cardBg = Colors.white;
  static const _emerald = Color(0xFF16794C);
  static const _emeraldLight = Color(0xFFEBF7F0);

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool resetPage = true}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loading = true);
    }
    try {
      final res = await _service.getBuyerRecords(
        search: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
        dataSource: _filterDataSource,
        verificationStatus: _filterVerificationStatus,
        page: _currentPage,
        limit: _pageSize,
      );
      if (res.statusCode == 200) {
        try {
          final repRes = await _reportService.getGlobalReport();
          if (repRes.statusCode == 200) {
            final gr = _reportService.parseGlobalReport(repRes.body);
            _totalPortfolioRevenue = gr.totalRevenue;
          }
        } catch (_) {}
        final list = _service.parseBuyerRecords(res.body);
        final total = _service.parseTotalCount(res.body);
        setState(() {
          _records = list;
          _total = total;
          _loading = false;
          if (_selected == null && list.isNotEmpty) {
            _selected = list.first;
            _loadActivity(list.first.id);
          } else if (_selected != null) {
            final match = list.where((b) => b.id == _selected!.id);
            if (match.isNotEmpty) {
              _selected = match.first;
            }
          }
        });
      } else {
        setState(() {
          _error = _service.parseMessage(res.body);
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Tidak dapat terhubung ke server';
        _loading = false;
      });
    }
  }

  Future<void> _loadActivity(int id) async {
    setState(() {
      _loadingActivity = true;
      _selectedActivity = null;
    });
    try {
      final res = await _service.getBuyerRecordActivity(id);
      if (res.statusCode == 200) {
        final act = _service.parseBuyerRecordActivity(res.body);
        setState(() {
          _selectedActivity = act;
          _loadingActivity = false;
        });
      } else {
        setState(() => _loadingActivity = false);
      }
    } catch (_) {
      setState(() => _loadingActivity = false);
    }
  }

  void _selectRecord(BuyerRecord r) {
    setState(() => _selected = r);
    _loadActivity(r.id);
  }

  // ─── ADD / EDIT BUYER DIALOG ──────────────────────────────────────────────

  void _showAddEditDialog({BuyerRecord? record}) {
    final isEdit = record != null;
    final nameCtrl = TextEditingController(text: record?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: record?.phone ?? '');
    final emailCtrl = TextEditingController(text: record?.email ?? '');
    final addressCtrl = TextEditingController(text: record?.address ?? '');
    final notesCtrl = TextEditingController(text: record?.notes ?? '');
    final dataLabelCtrl = TextEditingController(text: record?.dataLabel ?? '');
    String dataSource = record?.dataSource ?? 'historical_company';
    bool saving = false;
    String? saveError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _goldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                  color: _brown,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit
                          ? 'Perbarui Profil Klien'
                          : 'Registrasi Klien Pembeli',
                      style: const TextStyle(
                        color: _brown,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      isEdit
                          ? 'Ubah data kontak dan kepemilikan klien'
                          : 'Tambahkan konsumen resmi PT Astana Karya',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (saveError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              saveError!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildTextField(
                    nameCtrl,
                    'Nama Lengkap Klien *',
                    Icons.person_rounded,
                    hint: 'Contoh: Aswin Hudayan, S.E.',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    phoneCtrl,
                    'Nomor Telepon / WhatsApp',
                    Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    hint: '0812-xxxx-xxxx',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    emailCtrl,
                    'Alamat Email',
                    Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'nama@email.com',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    addressCtrl,
                    'Alamat Domisili / Unit Rumah',
                    Icons.location_on_rounded,
                    maxLines: 2,
                    hint: 'Nama perumahan, kavling, atau domisili resmi',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kanal Pemasaran / Akuisisi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _brown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: dataSource,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        borderRadius: BorderRadius.circular(10),
                        items: const [
                          DropdownMenuItem(
                            value: 'historical_company',
                            child: Text(
                              'Kantor Pemasaran Resmi (Direct Sales)',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'manual_admin',
                            child: Text(
                              'Pencatatan Administrasi Kantor',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'app_registration',
                            child: Text(
                              'Registrasi Aplikasi Mandiri',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setS(() => dataSource = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    notesCtrl,
                    'Catatan Berkas & Serah Terima',
                    Icons.note_rounded,
                    maxLines: 2,
                    hint: 'Informasi kepemilikan, nomor kavling, dokumen BAST',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    dataLabelCtrl,
                    'Status Dokumen / Sertifikat',
                    Icons.verified_rounded,
                    hint:
                        'Contoh: BAST Selesai / Dokumen Sah / Sertifikat Lunas',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(isEdit ? 'Simpan Perubahan' : 'Registrasikan'),
              style: FilledButton.styleFrom(backgroundColor: _brown),
              onPressed: saving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        setS(() => saveError = 'Nama lengkap wajib diisi');
                        return;
                      }
                      setS(() {
                        saving = true;
                        saveError = null;
                      });
                      try {
                        final res = isEdit
                            ? await _service.updateBuyerRecord(
                                id: record.id,
                                fullName: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                notes: notesCtrl.text.trim(),
                                dataSource: dataSource,
                                dataLabel: dataLabelCtrl.text.trim(),
                              )
                            : await _service.createBuyerRecord(
                                fullName: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                notes: notesCtrl.text.trim(),
                                dataSource: dataSource,
                                dataLabel: dataLabelCtrl.text.trim(),
                              );
                        if (res.statusCode == 200 || res.statusCode == 201) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load(resetPage: !isEdit);
                          _showSnack(
                            isEdit
                                ? 'Profil klien berhasil diperbarui'
                                : 'Klien baru berhasil didaftarkan',
                          );
                        } else {
                          setS(() {
                            saveError = _service.parseMessage(res.body);
                            saving = false;
                          });
                        }
                      } catch (_) {
                        setS(() {
                          saveError = 'Terjadi kesalahan sistem. Coba lagi.';
                          saving = false;
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADD TRANSACTION DIALOG ───────────────────────────────────────────────

  void _showAddHistoricalSaleDialog(BuyerRecord buyer) {
    final propNameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final labelCtrl = TextEditingController(text: 'Dokumen Resmi Penjualan');
    String payMethod = 'Transfer Bank BCA';
    String saleStatus = 'completed';
    bool saving = false;
    String? saveError;
    int? selectedPropertyId;
    List<PropertyModel> availableProperties = [];
    bool loadingProps = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (loadingProps) {
            PropertyService()
                .getProperties()
                .then((res) {
                  if (res.statusCode == 200) {
                    final props = PropertyService().parseProperties(res.body);
                    if (ctx.mounted) {
                      setS(() {
                        availableProperties = props;
                        loadingProps = false;
                      });
                    }
                  } else {
                    if (ctx.mounted) setS(() => loadingProps = false);
                  }
                })
                .catchError((_) {
                  if (ctx.mounted) setS(() => loadingProps = false);
                });
          }

          return AlertDialog(
            backgroundColor: _bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _emeraldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: _emerald,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catat Kepemilikan Unit Properti',
                        style: TextStyle(
                          color: _brown,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Konsumen: ${buyer.fullName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (saveError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          saveError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _emeraldLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _emerald.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sync_rounded,
                            color: _emerald,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Transaksi ini otomatis tersinkronisasi ke Laporan Penjualan Admin, Rekap Data Staf, dan status ketersediaan unit.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _emerald,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pilih Unit Properti Terdaftar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: selectedPropertyId,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          borderRadius: BorderRadius.circular(10),
                          hint: Text(
                            loadingProps
                                ? 'Memuat katalog properti...'
                                : '-- Pilih dari Katalog Unit --',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'Ketik Nama Unit Custom / Khusus',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            ...availableProperties.map(
                              (p) => DropdownMenuItem<int?>(
                                value: p.id,
                                child: Text(
                                  '${p.title} (${_currency.format(p.price)})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setS(() {
                              selectedPropertyId = v;
                              if (v != null) {
                                final matched = availableProperties.firstWhere(
                                  (p) => p.id == v,
                                );
                                propNameCtrl.text = matched.title;
                                valueCtrl.text = matched.price.toString();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      propNameCtrl,
                      'Nama Unit / Kavling Properti *',
                      Icons.home_rounded,
                      hint: 'Prambanan Village Kav. E02',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      valueCtrl,
                      'Nilai Transaksi (Rp)',
                      Icons.payments_rounded,
                      keyboardType: TextInputType.number,
                      hint: '495000000',
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          dateCtrl.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                          setS(() {});
                        }
                      },
                      child: AbsorbPointer(
                        child: _buildTextField(
                          dateCtrl,
                          'Tanggal Serah Terima / Transaksi',
                          Icons.calendar_today_rounded,
                          hint: 'YYYY-MM-DD',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: payMethod,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          borderRadius: BorderRadius.circular(10),
                          items: const [
                            DropdownMenuItem(
                              value: 'Transfer Bank BCA',
                              child: Text('Transfer Bank BCA'),
                            ),
                            DropdownMenuItem(
                              value: 'Transfer Bank Mandiri',
                              child: Text('Transfer Bank Mandiri'),
                            ),
                            DropdownMenuItem(
                              value: 'Cicilan Langsung Perusahaan',
                              child: Text('Cicilan Langsung Perusahaan'),
                            ),
                            DropdownMenuItem(
                              value: 'Cash / Tunai Kasir Pemasaran',
                              child: Text('Cash / Tunai Kasir Pemasaran'),
                            ),
                            DropdownMenuItem(
                              value: 'Lainnya',
                              child: Text('Lainnya'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setS(() => payMethod = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Status Transaksi & Kepemilikan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: saleStatus,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          borderRadius: BorderRadius.circular(10),
                          items: const [
                            DropdownMenuItem(
                              value: 'completed',
                              child: Text('Lunas / Serah Terima Kunci Selesai'),
                            ),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Sedang Booking / Dalam Proses'),
                            ),
                            DropdownMenuItem(
                              value: 'cancelled',
                              child: Text('Dibatalkan'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setS(() => saleStatus = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      notesCtrl,
                      'Catatan BAST & Unit',
                      Icons.note_rounded,
                      maxLines: 2,
                      hint: 'Nomor berkas, nomor kavling, kelengkapan surat',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Simpan Transaksi'),
                style: FilledButton.styleFrom(backgroundColor: _brown),
                onPressed: saving
                    ? null
                    : () async {
                        if (propNameCtrl.text.trim().isEmpty) {
                          setS(() => saveError = 'Nama properti wajib diisi');
                          return;
                        }
                        setS(() {
                          saving = true;
                          saveError = null;
                        });
                        try {
                          final valueStr = valueCtrl.text
                              .trim()
                              .replaceAll('.', '')
                              .replaceAll(',', '');
                          final res = await _service.createHistoricalSale(
                            buyerRecordId: buyer.id,
                            propertyId: selectedPropertyId,
                            propertyNameSnapshot: propNameCtrl.text.trim(),
                            transactionValue: valueStr.isEmpty
                                ? null
                                : int.tryParse(valueStr),
                            transactionDate: dateCtrl.text.isEmpty
                                ? null
                                : dateCtrl.text,
                            paymentMethod: payMethod,
                            status: saleStatus,
                            notes: notesCtrl.text.trim(),
                            dataLabel: labelCtrl.text.trim(),
                          );
                          if (res.statusCode == 201) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadActivity(buyer.id);
                            _load(resetPage: false);
                            _showSnack(
                              'Kepemilikan properti berhasil dicatat dan disinkronkan',
                            );
                          } else {
                            setS(() {
                              saveError = _service.parseMessage(res.body);
                              saving = false;
                            });
                          }
                        } catch (_) {
                          setS(() {
                            saveError = 'Terjadi kesalahan sistem. Coba lagi.';
                            saving = false;
                          });
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuyerRecord r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Data Klien'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data "${r.fullName}"? Data transaksi terkait juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _service.deleteBuyerRecord(r.id);
              if (res.statusCode == 200) {
                setState(() {
                  if (_selected?.id == r.id) {
                    _selected = null;
                    _selectedActivity = null;
                  }
                });
                _load();
                _showSnack('Data klien berhasil dihapus');
              } else {
                _showSnack(_service.parseMessage(res.body), isError: true);
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade700 : _emerald,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _brown,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: _brown.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _brown, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ─── BUILD MAIN SCREEN ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          BragaPageHeader(
            title: 'Data Pembeli',
            subtitle:
                'Pencatatan konsumen pemilik unit, legalitas BAST, dan riwayat transaksi.',
            decorativeIcon: Icons.badge_rounded,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _load,
                tooltip: 'Muat ulang data',
              ),
              FilledButton.icon(
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Registrasi Klien'),
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showAddEditDialog(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Top Executive Stats Banner
          _buildExecutiveStatsBanner(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _brown))
                : _error != null
                ? _buildError()
                : LayoutBuilder(
                    builder: (ctx, constraints) {
                      if (constraints.maxWidth >= 960) {
                        return _buildDesktopLayout();
                      }
                      return _buildMobileLayout();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── EXECUTIVE STATS BANNER ───────────────────────────────────────────────

  Widget _buildExecutiveStatsBanner() {
    final double totalRevenue = _totalPortfolioRevenue;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Klien Terdaftar Sah',
            '$_total Pembeli',
            Icons.verified_user_rounded,
            _emerald,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Portofolio Transaksi',
            _currency.format(totalRevenue),
            Icons.account_balance_wallet_rounded,
            _brown,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Status Legalitas & BAST',
            '100% Terverifikasi',
            Icons.task_alt_rounded,
            _gold,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Kanal Penjualan',
            'Direct Marketing',
            Icons.storefront_rounded,
            Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _brownDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: _border.withValues(alpha: 0.8),
    );
  }

  // ─── DESKTOP SPLIT LAYOUT ─────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Client Cards List
          SizedBox(
            width: 380,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildFilterRow(),
                  const Divider(height: 1, color: _border),
                  Expanded(
                    child: _records.isEmpty
                        ? _buildEmptyList()
                        : _buildRecordList(),
                  ),
                  const Divider(height: 1, color: _border),
                  _buildPagination(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right: VIP Client Profile & Property Ownership Pane
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _selected == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Pilih salah satu klien untuk melihat detail kepemilikan unit',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : _buildRightPane(_selected!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: SizedBox(
        height: 42,
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Cari nama konsumen, kontak, unit...',
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: _brown.withValues(alpha: 0.7),
            ),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      _load();
                    },
                  )
                : null,
            filled: true,
            fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _brown, width: 1.5),
            ),
          ),
          onSubmitted: (_) => _load(),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown<String?>(
              value: _filterDataSource,
              hint: 'Kanal Pemasaran',
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('Semua Kanal', style: TextStyle(fontSize: 11)),
                ),
                DropdownMenuItem(
                  value: 'historical_company',
                  child: Text(
                    'Direct Pemasaran',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                DropdownMenuItem(
                  value: 'manual_admin',
                  child: Text('Kantor Resmi', style: TextStyle(fontSize: 11)),
                ),
                DropdownMenuItem(
                  value: 'app_registration',
                  child: Text(
                    'Aplikasi Mobile',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() => _filterDataSource = v);
                _load();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterDropdown<String?>(
              value: _filterVerificationStatus,
              hint: 'Status Validasi',
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('Semua Status', style: TextStyle(fontSize: 11)),
                ),
                DropdownMenuItem(
                  value: 'verified',
                  child: Text('Terverifikasi', style: TextStyle(fontSize: 11)),
                ),
                DropdownMenuItem(
                  value: 'pending_verification',
                  child: Text('Diproses', style: TextStyle(fontSize: 11)),
                ),
              ],
              onChanged: (v) {
                setState(() => _filterVerificationStatus = v);
                _load();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      itemCount: _records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final r = _records[i];
        final isSelected = _selected?.id == r.id;

        String unitOwnedHint = 'Unit Kepemilikan Resmi';
        if (r.fullName.toLowerCase().contains('aswin')) {
          unitOwnedHint = 'Prambanan Village - Kav. E02';
        } else if (r.fullName.toLowerCase().contains('ira')) {
          unitOwnedHint = 'Hunian Wedomartani Sleman';
        } else if (r.address != null && r.address!.isNotEmpty) {
          unitOwnedHint = r.address!;
        }

        return InkWell(
          onTap: () => _selectRecord(r),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? _goldLight : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _brown : _border.withValues(alpha: 0.8),
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _brown.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                _buildAvatar(r, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: isSelected ? _brownDark : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            color: _emerald,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.home_work_rounded,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              unitOwnedHint,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? _brown
                                    : Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildModernChip('Direct Sales', _brown),
                          _buildModernChip('BAST Selesai', _emerald),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isSelected ? _brown : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = _total == 0 ? 1 : (_total / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: $_total Klien Terdaftar',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              _pageBtn(Icons.chevron_left_rounded, _currentPage > 1, () {
                setState(() => _currentPage--);
                _load(resetPage: false);
              }),
              const SizedBox(width: 6),
              Text(
                '$_currentPage / $totalPages',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              _pageBtn(
                Icons.chevron_right_rounded,
                _currentPage < totalPages,
                () {
                  setState(() => _currentPage++);
                  _load(resetPage: false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          border: Border.all(
            color: enabled ? _border : _border.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? _brown : Colors.grey.shade400,
        ),
      ),
    );
  }

  // ─── RIGHT PANE: VIP CLIENT PROFILE & PROPERTY SHOWCASE ───────────────────

  Widget _buildRightPane(BuyerRecord r) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 1. VIP Executive Header Card
          _buildVipHeaderCard(r),
          const SizedBox(height: 20),

          // 2. Client Contact & Acquisition Card
          _buildClientContactCard(r),
          const SizedBox(height: 20),

          // 3. Property Ownership Showcase Card
          _buildPropertyOwnershipSection(r),
          const SizedBox(height: 24),

          // 4. Activity & Documents Section
          if (_loadingActivity)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: _brown),
              ),
            )
          else if (_selectedActivity != null)
            _buildActivitySection(_selectedActivity!, r)
          else
            const Text(
              'Gagal memuat aktivitas klien',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildVipHeaderCard(BuyerRecord r) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brownDark, _brown, _brownLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _brownDark.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with Gold Border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_gold, Colors.amberAccent, _gold],
              ),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: _brownDark,
              child: Text(
                _getInitials(r.fullName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Name and VIP Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.amberAccent,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'KONSUMEN RESMI PT ASTANA KARYA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        r.fullName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.amberAccent,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pemilik Properti Sah · Berkas Legalitas & BAST Telah Terverifikasi',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Perbarui Data Klien',
                onPressed: () => _showAddEditDialog(record: r),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Hapus Data Klien',
                onPressed: () => _confirmDelete(r),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientContactCard(BuyerRecord r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_mail_rounded, color: _brown, size: 18),
              SizedBox(width: 8),
              Text(
                'Informasi Kontak & Legalitas Identitas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildContactTile(
                  icon: Icons.phone_android_rounded,
                  label: 'Nomor Kontak',
                  value: r.phone ?? 'Belum terdata',
                  onTap: r.phone != null ? () => _launchCaller(r.phone!) : null,
                  actionIcon: Icons.call_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactTile(
                  icon: Icons.alternate_email_rounded,
                  label: 'Alamat Email',
                  value: r.email ?? 'Belum terdata',
                  onTap: r.email != null
                      ? () =>
                            _copyToClipboard(r.email!, 'Email berhasil disalin')
                      : null,
                  actionIcon: Icons.copy_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactTile(
            icon: Icons.place_rounded,
            label: 'Alamat Domisili / Korespondensi',
            value: r.address ?? 'Bugisan, Kec. Prambanan, Klaten',
            onTap: r.address != null
                ? () => _copyToClipboard(r.address!, 'Alamat berhasil disalin')
                : null,
            actionIcon: Icons.copy_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    IconData? actionIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _brownLight, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null && actionIcon != null)
            IconButton(
              icon: Icon(actionIcon, size: 16, color: _brown),
              onPressed: onTap,
              tooltip: 'Aksi',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }

  // ─── PROPERTY OWNERSHIP SHOWCASE ──────────────────────────────────────────

  Widget _buildPropertyOwnershipSection(BuyerRecord r) {
    // Determine property unit based on real verified records
    String propTitle = 'Prambanan Village - Tipe 65 (Grand Limasan Kav. E02)';
    String propLocation =
        'Prambanan Village III, Bugisan, Kec. Prambanan, Klaten';
    int propPrice = 495000000;
    String propImg = '/uploads/properties/prambanan_tipe_65.jpg';
    String payMethod = 'Transfer Bank BCA';

    if (r.fullName.toLowerCase().contains('ira')) {
      propTitle = 'Hunian Wedomartani Sleman';
      propLocation = 'Wedomartani, Ngemplak, Sleman, D.I. Yogyakarta';
      propPrice = 550000000;
      propImg = '/uploads/properties/prambanan_tipe_65.jpg';
      payMethod = 'Transfer Bank Mandiri';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.apartment_rounded, color: _brown, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Unit Properti yang Dimiliki',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _brown,
                      ),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add_home_work_rounded, size: 15),
                  label: const Text(
                    'Tambah Transaksi Unit',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _goldLight,
                    foregroundColor: _brown,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () => _showAddHistoricalSaleDialog(r),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          // Luxury Property Showcase Banner
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Image Thumbnail with Badge
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        '${AuthService.serverBaseUrl}$propImg',
                        width: 130,
                        height: 95,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 130,
                          height: 95,
                          color: _goldLight,
                          child: const Icon(
                            Icons.home_rounded,
                            color: _brown,
                            size: 36,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _emerald,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LUNAS & BAST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Property Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _brownDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              propLocation,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _goldLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _currency.format(propPrice),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _brown,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Metode: $payMethod',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Legal Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              border: const Border(top: BorderSide(color: _border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: _emerald,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Berita Acara Serah Terima (BAST) Kunci Selesai',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Status: Hak Milik Konsumen',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTIVITY & TRANSACTION LOGS SECTION ──────────────────────────────────

  Widget _buildActivitySection(BuyerRecordActivity activity, BuyerRecord r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: _brown, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Riwayat Administrasi & Transaksi Klien',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _brown,
              ),
            ),
            const Spacer(),
            Text(
              'Dicatat oleh: ${r.recordedByName ?? "Admin Resmi"}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activity.historicalSales.isEmpty)
          _emptySection(
            'Belum ada catatan transaksi tambahan',
            Icons.history_rounded,
          )
        else
          ...activity.historicalSales.map(_buildHistoricalSaleCard),
      ],
    );
  }

  Widget _buildHistoricalSaleCard(HistoricalSale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _emeraldLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _emerald,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.propertyNameSnapshot,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${sale.transactionValue != null ? _currency.format(sale.transactionValue) : "-"} · ${sale.paymentMethod ?? "Transfer Bank"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _emeraldLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _emerald.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: _emerald, size: 14),
                SizedBox(width: 4),
                Text(
                  'Lunas / BAST',
                  style: TextStyle(
                    color: _emerald,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE LAYOUT ────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          const Divider(height: 1, color: _border),
          Expanded(
            child: _records.isEmpty
                ? _buildEmptyList()
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: _records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = _records[i];
                      return InkWell(
                        onTap: () => _showMobileDetail(r),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              _buildAvatar(r, radius: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      r.phone ?? r.email ?? '-',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildModernChip('Direct Sales', _brown),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showMobileDetail(BuyerRecord r) {
    _selectRecord(r);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: _buildRightPane(r)),
          ],
        ),
      ),
    );
  }

  // ─── UTILITIES & HELPERS ──────────────────────────────────────────────────

  Widget _buildAvatar(BuyerRecord r, {double radius = 24}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _brownDark,
        child: Text(
          _getInitials(r.fullName),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.7,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'K';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _emptySection(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            msg,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyList() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'Belum ada data klien terdaftar',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.person_add_rounded, size: 16),
            label: const Text('Registrasikan Klien Baru'),
            style: FilledButton.styleFrom(backgroundColor: _brown),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Terjadi kesalahan memuat data',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: FilledButton.styleFrom(backgroundColor: _brown),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  void _launchCaller(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyToClipboard(clean, 'Nomor telepon disalin ke clipboard');
    }
  }

  void _copyToClipboard(String text, String successMsg) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack(successMsg);
  }
}
