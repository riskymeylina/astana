import 'package:flutter/material.dart';

import '../../models/property_preferences_model.dart';
import '../../services/property_preferences_service.dart';
import '../../services/property_service.dart';
import 'property_search_page.dart';
import '../../widgets/braga_page_header.dart';

class PropertyPreferencesPage extends StatefulWidget {
  const PropertyPreferencesPage({super.key});

  @override
  State<PropertyPreferencesPage> createState() =>
      _PropertyPreferencesPageState();
}

class _PropertyPreferencesPageState extends State<PropertyPreferencesPage> {
  static const List<String> _klatenRegionSuggestions = [
    'Klaten',
    'Prambanan',
    'Manisrenggo',
    'Tlogo',
    'Bugisan',
    'Kebondalem Kidul',
    'Klaten Utara',
    'Klaten Tengah',
    'Klaten Selatan',
    'Jogonalan',
    'Kalikotes',
    'Ngawen',
    'Kebonarum',
    'Karangnongko',
    'Delanggu',
    'Ceper',
    'Pedan',
    'Wedi',
    'Cawas',
    'Bayat',
    'Karanganom',
    'Jatinom',
    'Polanharjo',
    'Tulung',
  ];

  final PropertyPreferencesService _service = PropertyPreferencesService();
  final PropertyService _propertyService = PropertyService();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<String> _selectedFacilities = [
    'Carport / Garage',
    'Taman',
    'Keamanan 24 Jam',
  ];
  List<String> _selectedCategories = ['Rumah'];
  List<String> _availableCategories = const [];
  List<String> _locationSuggestions = const [];
  RangeValues _priceRange = const RangeValues(100000000, 2000000000);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _service.getMyPropertyPreferences();
    final propertiesResponse = await _propertyService.getProperties(
      sortBy: 'latest',
    );
    if (!mounted) return;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _applyPropertyOptions(propertiesResponse);
      final preferences = _service.parsePreferences(response.body);
      _applyPreferences(preferences);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage = _service.parseMessage(response.body);
      _isLoading = false;
    });
  }

  void _applyPropertyOptions(ApiResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) return;
    final properties = _propertyService.parseProperties(response.body);
    final categories =
        properties
            .map((property) => property.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final locations =
        properties
            .map((property) => property.location.trim())
            .where((location) => location.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    setState(() {
      _availableCategories = categories;
      _locationSuggestions = locations;
      if (_availableCategories.isNotEmpty) {
        _selectedCategories = _selectedCategories
            .where(_availableCategories.contains)
            .toList();
        if (_selectedCategories.isEmpty) {
          _selectedCategories = [_availableCategories.first];
        }
      }
    });
  }

  void _applyPreferences(PropertyPreferencesModel preferences) {
    _locationController.text = preferences.preferredLocation;
    _notesController.text = preferences.notes;

    if (preferences.preferredCategories.isNotEmpty) {
      _selectedCategories = List.from(preferences.preferredCategories);
      if (_availableCategories.isEmpty) {
        _availableCategories = List.from(preferences.preferredCategories);
      }
    } else {
      _selectedCategories = _availableCategories.isNotEmpty
          ? [_availableCategories.first]
          : ['Rumah'];
    }

    final priceStart = preferences.minPrice?.toDouble() ?? _priceRange.start;
    final priceEnd = preferences.maxPrice?.toDouble() ?? _priceRange.end;
    setState(() {
      _priceRange = RangeValues(
        priceStart.clamp(100000000, 2000000000),
        priceEnd.clamp(priceStart, 2000000000),
      );
    });
  }

  Future<void> _savePreferences() async {
    final preferredLocation = _locationController.text.trim();
    if (preferredLocation.isEmpty) {
      _showMessage('Lokasi diminati wajib diisi.');
      return;
    }

    if (_selectedCategories.isEmpty) {
      _showMessage('Minimal satu kategori properti harus dipilih.');
      return;
    }

    final preferences = PropertyPreferencesModel(
      preferredCategories: _selectedCategories,
      preferredLocation: preferredLocation,
      minPrice: _priceRange.start.round(),
      maxPrice: _priceRange.end.round(),
      minBedrooms: null,
      minBathrooms: null,
      minBuildingArea: null,
      minLandArea: null,
      notes: _notesController.text.trim(),
    );

    setState(() {
      _isSaving = true;
    });

    final response = await _service.updateMyPropertyPreferences(preferences);
    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    _showMessage(_service.parseMessage(response.body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _applyPreferences(_service.parsePreferences(response.body));
      setState(() {});
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Preferensi Properti',
            subtitle: 'Preferensi sesuai minat.',
            decorativeIcon: Icons.tune_rounded,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionCard(
            title: 'Gagal memuat preferensi',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6D5540),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loadPreferences,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8E4E16),
                  ),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _SectionCard(
          title: 'Mengapa atur preferensi?',
          child: Text(
            'Kami akan memberikan rekomendasi properti yang lebih relevan sesuai preferensi yang Anda pilih.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6D5540),
              height: 1.4,
            ),
          ),
        ),
        _SectionCard(
          title: 'Kategori Properti',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...(_availableCategories.isEmpty
                  ? ['Belum ada kategori']
                  : _availableCategories),
            ].map(_buildCategoryChip).toList(),
          ),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: 'Lokasi Diminati',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationField(),
              if (_locationController.text.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      backgroundColor: const Color(0xFFFFF1E2),
                      label: Text(_locationController.text),
                      avatar: const Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: Color(0xFF8E4E16),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Rentang Harga',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceLabel(
                    'Rp ${(_priceRange.start / 1000000).round()} jt',
                  ),
                  _buildPriceLabel(
                    'Rp ${(_priceRange.end / 1000000).round()} jt',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000000000,
                divisions: 10,
                labels: RangeLabels(
                  'Rp ${(_priceRange.start / 1000000).round()}jt',
                  'Rp ${(_priceRange.end / 1000000).round()}jt',
                ),
                activeColor: const Color(0xFF8E4E16),
                inactiveColor: const Color(0xFFE7D3B8),
                onChanged: (values) {
                  setState(() {
                    _priceRange = RangeValues(values.start, values.end);
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Rp 0'),
                  Text('Rp 250 jt'),
                  Text('Rp 500 jt'),
                  Text('Rp 750 jt'),
                  Text('Rp 1 M+'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Fasilitas yang Diinginkan',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              'Carport / Garage',
              'Taman',
              'Keamanan 24 Jam',
              'Kolam Renang',
              'Balkon',
              'AC',
              'Dapur',
              'Ruang Kerja',
              'Lift',
            ].map(_buildSelectableChip).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Catatan Tambahan (Opsional)',
          child: _buildTextField(
            controller: _notesController,
            label: 'Tulis catatan Anda di sini...',
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 5,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _openPreferenceSearch,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Cari Properti Sesuai Preferensi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8E4E16),
              side: const BorderSide(color: Color(0xFF8E4E16)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _isSaving ? null : _savePreferences,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8E4E16),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Simpan Preferensi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _locationController.text),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return (_locationSuggestions.isEmpty
                  ? _klatenRegionSuggestions
                  : _locationSuggestions)
              .take(8);
        }

        final suggestions = _locationSuggestions.isEmpty
            ? _klatenRegionSuggestions
            : _locationSuggestions;
        return suggestions.where((city) => city.toLowerCase().contains(query));
      },
      onSelected: (selection) {
        setState(() {
          _locationController.text = selection;
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            if (textEditingController.text != _locationController.text) {
              textEditingController.value = TextEditingValue(
                text: _locationController.text,
                selection: TextSelection.collapsed(
                  offset: _locationController.text.length,
                ),
              );
            }

            textEditingController.addListener(() {
              _locationController.value = textEditingController.value;
            });

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              decoration: _buildInputDecoration(
                'Kota / kawasan yang diinginkan',
              ),
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label) {
    if (label == 'Belum ada kategori') {
      return const Chip(label: Text('Belum ada kategori tersedia'));
    }
    final selected = _selectedCategories.contains(label);
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          if (selected) {
            if (_selectedCategories.length > 1) {
              _selectedCategories.remove(label);
            } else {
              _showMessage('Minimal satu kategori properti harus dipilih.');
            }
          } else {
            _selectedCategories.add(label);
          }
        });
      },
      selectedColor: const Color(0xFFFFE4BF),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF8E4E16) : const Color(0xFF5A4736),
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: Color(0xFFE7CCAE)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _openPreferenceSearch() {
    final location = _locationController.text.trim();
    if (location.isEmpty || _selectedCategories.isEmpty) {
      _showMessage('Lengkapi lokasi dan kategori preferensi terlebih dahulu.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertySearchPage(
          initialQuery: location,
          initialCategory: _selectedCategories.join(','),
          minPrice: _priceRange.start.round(),
          maxPrice: _priceRange.end.round(),
          title: 'Properti Sesuai Preferensi',
        ),
      ),
    );
  }

  Widget _buildSelectableChip(String label) {
    final selected = _selectedFacilities.contains(label);
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          if (selected) {
            _selectedFacilities.remove(label);
          } else {
            _selectedFacilities.add(label);
          }
        });
      },
      selectedColor: const Color(0xFFFFE4BF),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF8E4E16) : const Color(0xFF5A4736),
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: Color(0xFFE7CCAE)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildPriceLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF3A2B1F),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: _buildInputDecoration(label),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFFFBF6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3C8A5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3C8A5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB97731), width: 1.4),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D7BF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3A2B1F),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
