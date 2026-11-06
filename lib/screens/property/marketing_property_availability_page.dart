import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../widgets/braga_page_header.dart';

// ─────────────────────────────────────────────────────────────────
// DATA MODEL LOKAL: STATUS KETERSEDIAAN
// ─────────────────────────────────────────────────────────────────
enum _AvailabilityStatus { tersedia, booking, terjual }

extension _AvailabilityStatusExt on _AvailabilityStatus {
  String get label {
    switch (this) {
      case _AvailabilityStatus.tersedia:
        return 'Tersedia';
      case _AvailabilityStatus.booking:
        return 'Sedang Dibooking';
      case _AvailabilityStatus.terjual:
        return 'Terjual';
    }
  }

  Color get badgeBg {
    switch (this) {
      case _AvailabilityStatus.tersedia:
        return const Color(0xFFDFF7E6);
      case _AvailabilityStatus.booking:
        return const Color(0xFFFFF3D9);
      case _AvailabilityStatus.terjual:
        return const Color(0xFFFCE8E6);
    }
  }

  Color get badgeFg {
    switch (this) {
      case _AvailabilityStatus.tersedia:
        return const Color(0xFF1F7A45);
      case _AvailabilityStatus.booking:
        return const Color(0xFF9A6700);
      case _AvailabilityStatus.terjual:
        return const Color(0xFFC0392B);
    }
  }

  Color get dotColor {
    switch (this) {
      case _AvailabilityStatus.tersedia:
        return const Color(0xFF3DAA6E);
      case _AvailabilityStatus.booking:
        return const Color(0xFFE9A800);
      case _AvailabilityStatus.terjual:
        return const Color(0xFFD94F3D);
    }
  }
}

_AvailabilityStatus _resolveStatus(PropertyModel p) {
  final s = p.status.trim();
  if (s.toLowerCase() == 'booking' || s == 'Sedang Dibooking') {
    return _AvailabilityStatus.booking;
  }
  if (s.toLowerCase() == 'sold' || s == 'Terjual') {
    return _AvailabilityStatus.terjual;
  }
  return _AvailabilityStatus.tersedia;
}

String _statusLabel(String status) {
  final s = status.trim();
  if (s.toLowerCase() == 'booking' || s == 'Sedang Dibooking') {
    return 'Sedang Dibooking';
  }
  if (s.toLowerCase() == 'sold' || s == 'Terjual') {
    return 'Terjual';
  }
  return 'Tersedia';
}

bool _matchesActiveFilter(String activeFilter, String propertyStatus) {
  String normalizeStatus(String status) {
    final normalized = status.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (normalized == 'available' || normalized == 'tersedia') {
      return 'tersedia';
    }
    if (normalized == 'booking' || normalized == 'sedang dibooking') {
      return 'booking';
    }
    if (normalized == 'sold' || normalized == 'terjual') {
      return 'terjual';
    }
    return normalized;
  }

  final filter = normalizeStatus(activeFilter);
  return filter == 'semua' || filter == normalizeStatus(propertyStatus);
}

// ─────────────────────────────────────────────────────────────────
// HALAMAN UTAMA
// ─────────────────────────────────────────────────────────────────
class MarketingPropertyAvailabilityPage extends StatefulWidget {
  const MarketingPropertyAvailabilityPage({super.key});

  @override
  State<MarketingPropertyAvailabilityPage> createState() =>
      _MarketingPropertyAvailabilityPageState();
}

class _MarketingPropertyAvailabilityPageState
    extends State<MarketingPropertyAvailabilityPage> {
  final PropertyService _propertyService = PropertyService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<PropertyModel> _allProperties = const [];
  String _activeFilter = 'semua';
  String _activeCategory = 'semua';
  String _sortBy = 'default';
  String _searchQuery = '';

  // Pagination
  int _currentPage = 1;
  int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _propertyService.getProperties();
    if (!mounted) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      setState(() {
        _errorMessage = _propertyService.parseMessage(response.body);
        _isLoading = false;
      });
      return;
    }

    final properties = _propertyService.parseProperties(response.body);
    setState(() {
      _allProperties = properties;
      if (_activeCategory != 'semua' &&
          !properties.any((property) => property.category == _activeCategory)) {
        _activeCategory = 'semua';
      }
      _isLoading = false;
      _currentPage = 1;
    });
  }

  List<PropertyModel> get _filteredProperties {
    final queryTerms = _searchQuery
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    final filtered = _allProperties.where((property) {
      if (!_matchesActiveFilter(_activeFilter, property.status)) return false;
      if (_activeCategory != 'semua' && property.category != _activeCategory) {
        return false;
      }
      if (queryTerms.isEmpty) return true;

      final searchableValues = [
        property.title,
        property.location,
        property.category,
        property.status,
        property.statusLabel,
        property.price.toString(),
        NumberFormat('#,##0', 'id_ID').format(property.price),
      ].join(' ').toLowerCase();
      return queryTerms.every(searchableValues.contains);
    }).toList();

    switch (_sortBy) {
      case 'name':
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case 'latest':
        filtered.sort((a, b) {
          final aUpdated = DateTime.tryParse(a.updatedAt ?? '');
          final bUpdated = DateTime.tryParse(b.updatedAt ?? '');
          if (aUpdated == null) return bUpdated == null ? 0 : 1;
          if (bUpdated == null) return -1;
          return bUpdated.compareTo(aUpdated);
        });
    }
    return filtered;
  }

  int get _totalPages =>
      (_filteredProperties.length / _perPage).ceil().clamp(1, 9999);

  List<PropertyModel> get _pagedProperties {
    final all = _filteredProperties;
    final start = (_currentPage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, all.length);
    if (start >= all.length) return const [];
    return all.sublist(start, end);
  }

  int _countByFilter(String filter) {
    if (filter == 'semua') return _allProperties.length;
    return _allProperties
        .where((p) => _matchesActiveFilter(filter, p.status))
        .length;
  }

  int get _activeFilterCount =>
      (_activeFilter == 'semua' ? 0 : 1) +
      (_activeCategory == 'semua' ? 0 : 1) +
      (_sortBy == 'default' ? 0 : 1);

  List<String> get _availableCategories {
    final categories =
        _allProperties
            .map((property) => property.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }

  Future<void> _showFilterDialog() async {
    var selectedStatus = _activeFilter;
    var selectedCategory = _activeCategory;
    var selectedSortBy = _sortBy;
    final categories = _availableCategories;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Filter Properti',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterDropdown(
                  label: 'Status',
                  value: selectedStatus,
                  options: const [
                    ('semua', 'Semua status'),
                    ('Tersedia', 'Tersedia'),
                    ('Sedang Dibooking', 'Booking'),
                    ('Terjual', 'Terjual'),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                _FilterDropdown(
                  label: 'Tipe Properti',
                  value: selectedCategory,
                  options: [
                    const ('semua', 'Semua tipe'),
                    ...categories.map((category) => (category, category)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                _FilterDropdown(
                  label: 'Urutkan',
                  value: selectedSortBy,
                  options: const [
                    ('default', 'Urutan bawaan'),
                    ('latest', 'Pembaruan terbaru'),
                    ('name', 'Nama A–Z'),
                    ('price_low', 'Harga terendah'),
                    ('price_high', 'Harga tertinggi'),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedSortBy = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  selectedStatus = 'semua';
                  selectedCategory = 'semua';
                  selectedSortBy = 'default';
                });
              },
              child: const Text('Atur Ulang'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8F4E1E),
              ),
              onPressed: () {
                setState(() {
                  _activeFilter = selectedStatus;
                  _activeCategory = selectedCategory;
                  _sortBy = selectedSortBy;
                  _currentPage = 1;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _setPage(int page) {
    setState(() => _currentPage = page);
  }

  // Dialog ubah status properti
  Future<void> _showUbahStatusDialog(PropertyModel property) async {
    var selected = property.status;
    final statusOptions = ['Tersedia', 'Sedang Dibooking', 'Terjual'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ubah Status Ketersediaan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                property.title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A6552),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statusOptions.map((status) {
              final optionStatus = _resolveStatus(
                PropertyModel(
                  id: property.id,
                  title: property.title,
                  category: property.category,
                  location: property.location,
                  price: property.price,
                  status: status,
                  statusLabel: _statusLabel(status),
                  gallery: property.gallery,
                ),
              );
              final isSelected = selected == status;
              return GestureDetector(
                onTap: () => setDialogState(() => selected = status),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? optionStatus.badgeBg
                        : const Color(0xFFFAF5EF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? optionStatus.dotColor
                          : const Color(0xFFE9D7BF),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: optionStatus.dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? optionStatus.badgeFg
                              : const Color(0xFF3A2B1F),
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: optionStatus.dotColor,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8F4E1E),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _updatePropertyStatus(property, selected);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePropertyStatus(
    PropertyModel property,
    String status,
  ) async {
    final response = await _propertyService.updatePropertyStatus(
      property.id,
      status,
    );
    if (!mounted) return;

    final message = _propertyService.parseMessage(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF3DAA6E),
        ),
      );
      _loadProperties();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFC74C4C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BragaPageHeader(
            title: 'Ketersediaan Properti',
            subtitle: 'Kelola dan konfirmasi ketersediaan unit properti Anda',
            decorativeIcon: Icons.home_work_outlined,
          ),
          if (!_isLoading && _errorMessage == null) ...[
            _buildSummaryStats(),
            _buildFilterAndSearch(),
          ],
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF8F4E1E),
              onRefresh: _loadProperties,
              child: _buildBody(),
            ),
          ),
          if (!_isLoading &&
              _errorMessage == null &&
              _filteredProperties.isNotEmpty)
            _buildPaginationBar(),
        ],
      ),
    );
  }

  // ── SUMMARY STATS (4 KOLOM) ────────────────────────────────────
  Widget _buildSummaryStats() {
    final total = _allProperties.length;
    final tersedia = _countByFilter('Tersedia');
    final booking = _countByFilter('Sedang Dibooking');
    final sold = _countByFilter('Terjual');

    final stats = [
      _StatItem(
        valueColor: const Color(0xFF6F3212),
        count: total,
        label: 'Total Properti',
        sublabel: 'Semua properti terdaftar',
      ),
      _StatItem(
        valueColor: const Color(0xFF16794C),
        count: tersedia,
        label: 'Tersedia',
        sublabel: 'Siap dijual',
      ),
      _StatItem(
        valueColor: const Color(0xFFC78928),
        count: booking,
        label: 'Booking',
        sublabel: 'Sedang dipesan',
      ),
      _StatItem(
        valueColor: const Color(0xFFD94F3D),
        count: sold,
        label: 'Terjual',
        sublabel: 'Sudah selesai',
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9D7BF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stat.count}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: stat.valueColor,
                    ),
                  ),
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2A1A0E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stat.sublabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9A8070),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SEARCH + FILTER ────────────────────────────────────────────
  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE0CCBA)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(
              Icons.search_rounded,
              size: 18,
              color: Color(0xFF9A8070),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                }),
                style: const TextStyle(fontSize: 13, color: Color(0xFF3A2B1F)),
                decoration: InputDecoration(
                  hintText: 'Cari properti, lokasi, tipe, atau status...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBBA899),
                  ),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: Color(0xFF9A8070),
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: const Color(0xFFEFE5DB)),
            SizedBox(
              width: 112,
              height: double.infinity,
              child: TextButton.icon(
                onPressed: _showFilterDialog,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6F3212),
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(999),
                    ),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text(
                  'Filter',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BODY ───────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8F4E1E)),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _MessageCard(
            icon: Icons.cloud_off_rounded,
            iconColor: const Color(0xFFD94F3D),
            iconBg: const Color(0xFFFCE8E6),
            title: 'Gagal memuat properti',
            message: _errorMessage!,
            action: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8F4E1E),
              ),
              onPressed: _loadProperties,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba lagi'),
            ),
          ),
        ],
      );
    }

    if (_filteredProperties.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _MessageCard(
            icon: Icons.home_work_rounded,
            iconColor: const Color(0xFF8F4E1E),
            iconBg: const Color(0xFFFFF0E0),
            title: _searchQuery.isNotEmpty || _activeFilterCount > 0
                ? 'Tidak ada properti ditemukan'
                : 'Belum ada properti tersedia',
            message: _searchQuery.isNotEmpty || _activeFilterCount > 0
                ? 'Coba ubah filter atau kata kunci pencarian Anda.'
                : 'Data properti aktif akan muncul di sini.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _pagedProperties.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final property = _pagedProperties[index];
        return _PropertyCard(
          property: property,
          status: _resolveStatus(property),
          onDetail: () => Navigator.pushNamed(
            context,
            '/property-detail',
            arguments: property.id,
          ),
          onUbahStatus: () => _showUbahStatusDialog(property),
        );
      },
    );
  }

  // ── PAGINATION ─────────────────────────────────────────────────
  Widget _buildPaginationBar() {
    final total = _filteredProperties.length;
    final startItem = ((_currentPage - 1) * _perPage) + 1;
    final endItem = (_currentPage * _perPage).clamp(0, total);

    // Buat daftar halaman yang ditampilkan (maks 5 tombol + ellipsis)
    List<int?> pages = _buildPageList(_currentPage, _totalPages);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDE0CF))),
      ),
      child: Row(
        children: [
          Text(
            'Menampilkan $startItem – $endItem dari $total properti',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A6552),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Tombol prev
          _PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: _currentPage > 1,
            onTap: () => _setPage(_currentPage - 1),
          ),
          const SizedBox(width: 4),
          // Tombol halaman
          ...pages.map((p) {
            if (p == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '...',
                  style: TextStyle(
                    color: Color(0xFF9A8070),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            final isActive = p == _currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => _setPage(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF8F4E1E)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF8F4E1E)
                          : const Color(0xFFE0CCBA),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$p',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF5A3A22),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          // Tombol next
          _PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: _currentPage < _totalPages,
            onTap: () => _setPage(_currentPage + 1),
          ),
          const SizedBox(width: 12),
          // Per page selector
          _PerPageSelector(
            value: _perPage,
            onChanged: (v) => setState(() {
              _perPage = v;
              _currentPage = 1;
            }),
          ),
        ],
      ),
    );
  }

  List<int?> _buildPageList(int current, int total) {
    if (total <= 7) return List.generate(total, (i) => i + 1);
    final pages = <int?>[1];
    if (current > 3) pages.add(null);
    for (
      int i = (current - 1).clamp(2, total - 1);
      i <= (current + 1).clamp(2, total - 1);
      i++
    ) {
      pages.add(i);
    }
    if (current < total - 2) pages.add(null);
    if (total > 1) pages.add(total);
    return pages;
  }
}

// ─────────────────────────────────────────────────────────────────
// KARTU PROPERTI
// ─────────────────────────────────────────────────────────────────
class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final _AvailabilityStatus status;
  final VoidCallback onDetail;
  final VoidCallback onUbahStatus;

  const _PropertyCard({
    required this.property,
    required this.status,
    required this.onDetail,
    required this.onUbahStatus,
  });

  String get _imageUrl {
    if (property.gallery.isNotEmpty &&
        property.gallery.first.imageUrl.isNotEmpty) {
      return property.gallery.first.imageUrl;
    }
    return '';
  }

  String _formatLastUpdated() {
    final raw = property.updatedAt;
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt) + ' WIB';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9D7BF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── FOTO PROPERTI ──────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: SizedBox(
                width: 140,
                child: _imageUrl.isNotEmpty
                    ? Image.network(
                        _imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _PhotoPlaceholder(),
                      )
                    : _PhotoPlaceholder(),
              ),
            ),

            // ── KONTEN TENGAH ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2A1A0E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Lokasi
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF8A6A48),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            property.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A6A48),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Spesifikasi chips — sesuaikan dengan field di PropertyModel Anda
                    // Contoh: tambahkan property.type, property.landArea, dst.
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (property.category.isNotEmpty)
                          _SpecChip(label: property.category),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ── DIVIDER ────────────────────────────────────────
            Container(width: 1, color: const Color(0xFFEEDDCC)),

            // ── PANEL KANAN: STATUS + AKSI ─────────────────────
            SizedBox(
              width: 180,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header panel kanan
                    Row(
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9A8070),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onUbahStatus,
                          child: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: Color(0xFF9A8070),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Badge status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: status.badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: status.dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: status.badgeFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Terakhir diperbarui
                    const Text(
                      'Terakhir Diperbarui',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A8070),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatLastUpdated(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5A4535),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Tombol aksi side-by-side
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onDetail,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8F4E1E),
                              side: const BorderSide(color: Color(0xFF8F4E1E)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Detail',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: FilledButton(
                            onPressed: onUbahStatus,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF8F4E1E),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// KOMPONEN PENDUKUNG
// ─────────────────────────────────────────────────────────────────

class _StatItem {
  final Color valueColor;
  final int count;
  final String label;
  final String sublabel;
  const _StatItem({
    required this.valueColor,
    required this.count,
    required this.label,
    required this.sublabel,
  });
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5A4535),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFCF9F5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE9D7BF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE9D7BF)),
            ),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option.$1,
                  child: Text(
                    option.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5EAD8),
      child: const Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 36,
          color: Color(0xFFCB9A6A),
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final String label;
  const _SpecChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5ECD8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7A5230),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
  final Widget? action;

  const _MessageCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D7BF)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6D5540)),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0CCBA)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF5A3A22) : const Color(0xFFCCBBAA),
        ),
      ),
    );
  }
}

class _PerPageSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _PerPageSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0CCBA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3A2B1F),
          ),
          items: [5, 10, 20, 50]
              .map(
                (v) => DropdownMenuItem(value: v, child: Text('$v / halaman')),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
