import 'package:flutter/material.dart';

import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../widgets/braga_page_header.dart';
import '../../widgets/property_filter_sheet.dart';

class PropertySearchPage extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  final String? brand;
  final int? minPrice;
  final int? maxPrice;
  final String? status;
  final String? sortBy;
  final String title;

  const PropertySearchPage({
    super.key,
    this.initialQuery,
    this.initialCategory,
    this.brand,
    this.minPrice,
    this.maxPrice,
    this.status,
    this.sortBy,
    this.title = 'Cari Properti',
  });

  @override
  State<PropertySearchPage> createState() => _PropertySearchPageState();
}

class _PropertySearchPageState extends State<PropertySearchPage> {
  final PropertyService _propertyService = PropertyService();
  late final TextEditingController _searchController;
  late String? _query = widget.initialQuery;
  bool _isLoading = true;
  String? _errorMessage;
  List<PropertyModel> _properties = const [];

  String? _selectedStatus;
  int? _minPrice;
  int? _maxPrice;
  String? _selectedSortBy;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _selectedStatus = widget.status;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _selectedSortBy = widget.sortBy;
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

    final response = await _propertyService.getProperties(
      query: _query,
      category: widget.initialCategory,
      brand: widget.brand,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      status: _selectedStatus,
      sortBy: _selectedSortBy,
    );

    if (!mounted) return;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      setState(() {
        _errorMessage = _propertyService.parseMessage(response.body);
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _properties = _propertyService.parseProperties(response.body);
      _isLoading = false;
    });
  }

  void _submitSearch(String value) {
    setState(() => _query = value.trim());
    _loadProperties();
  }

  void _openPropertyDetail(PropertyModel property) {
    Navigator.pushNamed(context, '/property-detail', arguments: property.id);
  }

  void _showFilterSheet() async {
    final result = await PropertyFilterSheet.show(
      context,
      initialStatus: _selectedStatus,
      initialMinPrice: _minPrice,
      initialMaxPrice: _maxPrice,
      initialSortBy: _selectedSortBy,
    );

    if (result != null && mounted) {
      setState(() {
        _selectedStatus = result['status'] as String?;
        _minPrice = result['minPrice'] as int?;
        _maxPrice = result['maxPrice'] as int?;
        _selectedSortBy = result['sortBy'] as String?;
      });
      _loadProperties();
    }
  }

  List<String> get _activeFilters {
    final filters = <String>[];
    if (widget.initialCategory?.isNotEmpty == true) {
      filters.add('Kategori: ${widget.initialCategory}');
    }
    if (widget.brand?.isNotEmpty == true) filters.add(widget.brand!);
    
    if (_selectedStatus != null) {
      final s = _selectedStatus!.toLowerCase();
      if (s == 'available' || s == 'tersedia') filters.add('Status: Tersedia');
      if (s == 'booking' || s == 'sedang dibooking') filters.add('Status: Dipesan');
      if (s == 'sold' || s == 'terjual') filters.add('Status: Terjual');
    }
    if (_minPrice != null && _maxPrice != null) {
      if (_minPrice == 100000000 && _maxPrice == 2000000000) {
        // Do not add "Semua Harga" chip
      } else {
        filters.add('Min ${_propertyService.formatPrice(_minPrice!)}');
        if (widget.title != 'Harga Terjangkau') {
          filters.add('Maks ${_propertyService.formatPrice(_maxPrice!)}');
        }
      }
    } else {
      if (_minPrice != null) {
        filters.add('Min ${_propertyService.formatPrice(_minPrice!)}');
      }
      if (_maxPrice != null) {
        if (widget.title != 'Harga Terjangkau') {
          filters.add('Maks ${_propertyService.formatPrice(_maxPrice!)}');
        }
      }
    }
    if (_selectedSortBy != null && _selectedSortBy != 'latest') {
      if (widget.title != 'Harga Terjangkau') {
        if (_selectedSortBy == 'price_low') filters.add('Urutan: Harga Terendah');
        if (_selectedSortBy == 'price_high') filters.add('Urutan: Harga Tertinggi');
      }
    }
    return filters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: Column(
        children: [
          BragaPageHeader(
            title: widget.title,
            subtitle: 'Temukan properti yang sesuai kebutuhan.',
            decorativeIcon: Icons.search_rounded,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProperties,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  _buildSearchBox(),
                  const SizedBox(height: 12),
                  if (_activeFilters.isNotEmpty) _buildFilterChips(),
                  if (_activeFilters.isNotEmpty) const SizedBox(height: 12),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _submitSearch,
      decoration: InputDecoration(
        hintText: 'Cari nama, lokasi, kategori...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          onPressed: _showFilterSheet,
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF8E4E16)),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE3CFB6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE3CFB6)),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _activeFilters
          .map(
            (filter) => Chip(
              label: Text(filter),
              backgroundColor: const Color(0xFFFFE7C2),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _StateCard(
        icon: Icons.wifi_off_rounded,
        message: _errorMessage!,
        buttonLabel: 'Coba Lagi',
        onPressed: _loadProperties,
      );
    }

    if (_properties.isEmpty) {
      return _StateCard(
        icon: Icons.search_off_rounded,
        message: 'Properti tidak ditemukan. Coba kata kunci atau filter lain.',
        buttonLabel: 'Muat Ulang',
        onPressed: _loadProperties,
      );
    }

    return Column(
      children: _properties
          .map(
            (property) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PropertyResultCard(
                property: property,
                propertyService: _propertyService,
                onTap: () => _openPropertyDetail(property),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PropertyResultCard extends StatelessWidget {
  final PropertyModel property;
  final PropertyService propertyService;
  final VoidCallback onTap;

  const _PropertyResultCard({
    required this.property,
    required this.propertyService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = property.gallery.isNotEmpty ? property.gallery.first.imageUrl : '';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6D4BC)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 88,
                          height: 88,
                          color: const Color(0xFFF0E0CF),
                          child: const Icon(Icons.image_not_supported_rounded),
                        ),
                      )
                    : Container(
                        width: 88,
                        height: 88,
                        color: const Color(0xFFF0E0CF),
                        child: const Icon(Icons.apartment_rounded),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2F2318),
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      property.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF786351),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      propertyService.formatPrice(property.price),
                      style: const TextStyle(
                        color: Color(0xFFCB7D2A),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      property.category,
                      style: const TextStyle(
                        color: Color(0xFF8E4E16),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.statusLabel,
                      style: const TextStyle(
                        color: Color(0xFF6B5744),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB28B62)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _StateCard({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D4BC)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF8E4E16)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
