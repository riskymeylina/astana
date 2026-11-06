import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/admin_models.dart';
import '../../../services/admin_property_service.dart';
import '../../../widgets/braga_page_header.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Properties Page
// ─────────────────────────────────────────────────────────────────────────────

class AdminPropertiesPage extends StatefulWidget {
  const AdminPropertiesPage({super.key});

  @override
  State<AdminPropertiesPage> createState() => _AdminPropertiesPageState();
}

class _AdminPropertiesPageState extends State<AdminPropertiesPage>
    with SingleTickerProviderStateMixin {
  final AdminPropertyService _service = AdminPropertyService();
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  List<AdminPropertyModel> _allProperties = [];
  List<AdminPropertyModel> _filteredProperties = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  String _selectedStatus = 'Semua Status';
  String _selectedSort = 'Terbaru';

  static const _statusOptions = [
    'Semua Status',
    'Tersedia',
    'Booking',
    'Terjual',
  ];
  static const _sortOptions = ['Terbaru', 'Terlama', 'Harga Tertinggi', 'Harga Terendah'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _searchController.addListener(_applyFilters);
    _loadProperties();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _fadeController.reset();

    final response = await _service.getProperties();
    if (!mounted) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      setState(() {
        _errorMessage = _service.parseMessage(response.body);
        _isLoading = false;
      });
      return;
    }

    final properties = _service.parseProperties(response.body);
    setState(() {
      _allProperties = properties;
      _isLoading = false;
    });
    _applyFilters();
    _fadeController.forward();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    var result = List<AdminPropertyModel>.from(_allProperties);

    // Search
    if (query.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.title.toLowerCase().contains(query) ||
                p.location.toLowerCase().contains(query),
          )
          .toList();
    }

    // Status filter
    if (_selectedStatus != 'Semua Status') {
      String filterDbStatus = '';
      if (_selectedStatus == 'Tersedia') filterDbStatus = 'available';
      if (_selectedStatus == 'Booking') filterDbStatus = 'booking';
      if (_selectedStatus == 'Terjual') filterDbStatus = 'sold';

      result = result
          .where(
            (p) =>
                p.status.toLowerCase() == filterDbStatus,
          )
          .toList();
    }

    // Sort
    switch (_selectedSort) {
      case 'Terlama':
        result.sort((a, b) => a.id.compareTo(b.id));
      case 'Harga Tertinggi':
        result.sort((a, b) => b.price.compareTo(a.price));
      case 'Harga Terendah':
        result.sort((a, b) => a.price.compareTo(b.price));
      default: // Terbaru
        result.sort((a, b) => b.id.compareTo(a.id));
    }

    setState(() => _filteredProperties = result);
  }

  void _onStatusChanged(String? value) {
    if (value == null) return;
    setState(() => _selectedStatus = value);
    _applyFilters();
  }

  void _onSortChanged(String? value) {
    if (value == null) return;
    setState(() => _selectedSort = value);
    _applyFilters();
  }

  Future<void> _deleteProperty(AdminPropertyModel property) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteConfirmDialog(property: property),
    );
    if (confirm != true || !mounted) return;

    final response = await _service.deleteProperty(property.id);
    if (!mounted) return;

    final message = _service.parseMessage(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _showSnackbar(message, isError: false);
      _loadProperties();
    } else {
      _showSnackbar(message, isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFC74C4C) : const Color(0xFF4C7C4C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToForm({AdminPropertyModel? property}) async {
    final result = await Navigator.pushNamed(
      context,
      '/admin/add-property',
      arguments: property,
    );
    if (result == true && mounted) {
      _loadProperties();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F0),
      body: Column(
        children: [
          // ── Hero Header ─────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: BragaPageHeader(
              title: 'Kelola Data Properti',
              subtitle: 'Kelola, pantau, dan perbarui seluruh data properti Anda dengan mudah.',
              onBack: () => Navigator.maybePop(context),
            ),
          ),

          // ── Search & Filter Bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SearchFilterBar(
              searchController: _searchController,
              selectedStatus: _selectedStatus,
              selectedSort: _selectedSort,
              statusOptions: _statusOptions,
              sortOptions: _sortOptions,
              onStatusChanged: _onStatusChanged,
              onSortChanged: _onSortChanged,
            ),
          ),

          // ── List ─────────────────────────────────────────────────────────────
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const _PropertyListSkeleton();
    }
    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _loadProperties,
      );
    }
    if (_filteredProperties.isEmpty) {
      return _EmptyState(
        isFiltered: _searchController.text.isNotEmpty ||
            _selectedStatus != 'Semua Status',
        onReset: () {
          _searchController.clear();
          setState(() => _selectedStatus = 'Semua Status');
          _applyFilters();
        },
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filteredProperties.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final property = _filteredProperties[index];
          return _PropertyListItem(
            property: property,
            onEdit: () => _navigateToForm(property: property),
            onDelete: () => _deleteProperty(property),
            onTap: () => Navigator.pushNamed(
              context,
              '/property-detail',
              arguments: property.id,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToForm(),
      backgroundColor: const Color(0xFF8E3A00),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: const Text(
        'Tambah Properti',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search & Filter Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final String selectedSort;
  final List<String> statusOptions;
  final List<String> sortOptions;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onSortChanged;

  const _SearchFilterBar({
    required this.searchController,
    required this.selectedStatus,
    required this.selectedSort,
    required this.statusOptions,
    required this.sortOptions,
    required this.onStatusChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2D0BB)),
          ),
          child: TextField(
            controller: searchController,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF2F2318),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Cari nama properti atau lokasi...',
              hintStyle: const TextStyle(
                color: Color(0xFFBEA48A),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFFBEA48A),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              suffixIcon: ValueListenableBuilder(
                valueListenable: searchController,
                builder: (_, value, _) => value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFBEA48A),
                          size: 18,
                        ),
                        onPressed: searchController.clear,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Filter dropdowns
        Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                icon: Icons.filter_list_rounded,
                value: selectedStatus,
                items: statusOptions,
                onChanged: onStatusChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterDropdown(
                icon: Icons.swap_vert_rounded,
                value: selectedSort,
                items: sortOptions,
                onChanged: onSortChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2D0BB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFBEA48A),
            size: 18,
          ),
          isExpanded: true,
          style: const TextStyle(
            color: Color(0xFF2F2318),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFFBEA48A), size: 15),
                      const SizedBox(width: 6),
                      Text(item),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Property List Item
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyListItem extends StatelessWidget {
  final AdminPropertyModel property;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyListItem({
    required this.property,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String get _imageUrl => property.imageUrl ?? '';

  String get _formattedPrice {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(property.price);
  }

  String get _formattedDate => '-';
  String get _formattedTime => '';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECDDCC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              _PropertyThumbnail(imageUrl: _imageUrl),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2F2318),
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _PropertyMenuButton(
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 12,
                          color: Color(0xFF9E856C),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF9E856C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Specs chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (property.category.isNotEmpty)
                          _SpecChip(
                            icon: Icons.category_rounded,
                            label: property.category,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Price + Status + Date row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Harga',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9E856C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formattedPrice,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8E3A00),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: property.status),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 10,
                                  color: Color(0xFF9E856C),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formattedDate,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B5240),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (_formattedTime.isNotEmpty)
                              Text(
                                _formattedTime,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9E856C),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyThumbnail extends StatelessWidget {
  final String imageUrl;
  const _PropertyThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 86,
        height: 86,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _PlaceholderImage(),
              )
            : _PlaceholderImage(),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0E0CF),
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: Color(0xFFCB7D2A),
        size: 28,
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF0E6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEEDAC4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF9E856C)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B5240),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bg;
    Color fg;
    IconData icon;
    String labelText;

    if (lower == 'available') {
      bg = const Color(0xFFE8F8EE);
      fg = const Color(0xFF2A9D5C);
      icon = Icons.check_circle_rounded;
      labelText = 'Tersedia';
    } else if (lower == 'booking') {
      bg = const Color(0xFFFFF4DC);
      fg = const Color(0xFFB07B10);
      icon = Icons.bookmark_rounded;
      labelText = 'Booking';
    } else if (lower == 'sold') {
      bg = const Color(0xFFFFEAEA);
      fg = const Color(0xFFC74C4C);
      icon = Icons.cancel_rounded;
      labelText = 'Terjual';
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade600;
      icon = Icons.info_outline;
      labelText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            labelText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyMenuButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyMenuButton({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      icon: const Icon(
        Icons.more_vert_rounded,
        color: Color(0xFFBEA48A),
        size: 20,
      ),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          height: 42,
          child: Row(
            children: const [
              Icon(Icons.edit_rounded, size: 16, color: Color(0xFF6B5240)),
              SizedBox(width: 10),
              Text(
                'Edit Properti',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F2318),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'delete',
          height: 42,
          child: Row(
            children: const [
              Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFC74C4C)),
              SizedBox(width: 10),
              Text(
                'Hapus Properti',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC74C4C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Loader
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyListSkeleton extends StatelessWidget {
  const _PropertyListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFECDDCC).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onReset;

  const _EmptyState({required this.isFiltered, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0DC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(0xFFCB7D2A),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'Tidak ada hasil' : 'Belum ada properti',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2F2318),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Coba ubah filter atau kata pencarian Anda'
                  : 'Tambahkan properti pertama Anda',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9E856C),
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8E3A00),
                ),
                child: const Text(
                  'Reset Filter',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────────────────

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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAEA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFC74C4C),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2F2318),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9E856C)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E3A00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Confirm Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final AdminPropertyModel property;

  const _DeleteConfirmDialog({required this.property});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFC74C4C), size: 24),
          SizedBox(width: 10),
          Text(
            'Hapus Properti',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F2318),
            ),
          ),
        ],
      ),
      content: Text(
        'Apakah Anda yakin ingin menghapus "${property.title}"? Tindakan ini tidak dapat dibatalkan.',
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF6B5240),
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B5240)),
          child: const Text(
            'Batal',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC74C4C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Ya, Hapus',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}