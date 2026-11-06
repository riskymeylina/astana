import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/admin_models.dart';
import '../../services/admin_property_service.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../widgets/braga_page_header.dart';

class SelectedImage {
  final XFile file;
  final Uint8List bytes;
  SelectedImage(this.file, this.bytes);
}

class AddPropertyPage extends StatefulWidget {
  final AdminPropertyModel? property;

  const AddPropertyPage({super.key, this.property});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final AdminPropertyService _service = AdminPropertyService();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedCategory = 'Rumah/Perumahan';
  String _selectedStatus = 'Tersedia';

  List<SelectedImage> _selectedFiles = [];

  final PropertyService _propertyService = PropertyService();
  List<PropertyGalleryItem> _existingImages = [];
  bool _loadingImages = false;
  final Set<int> _deletingImageIds = {};

  final List<String> _categories = [
    'Rumah/Perumahan',
  ];
  final List<String> _statuses = ['Tersedia', 'Sedang Dibooking', 'Terjual'];

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    if (p != null) {
      _titleController.text = p.title;
      _priceController.text = p.price.toStringAsFixed(0);
      _locationController.text = p.location;
      _selectedCategory = p.category.isNotEmpty ? p.category : _selectedCategory;
      
      String statusVal = p.status;
      if (statusVal == 'available') statusVal = 'Tersedia';
      if (statusVal == 'booking') statusVal = 'Sedang Dibooking';
      if (statusVal == 'sold') statusVal = 'Terjual';
      _selectedStatus = statusVal.isNotEmpty ? statusVal : _selectedStatus;

      if (!_categories.contains(_selectedCategory)) {
        _categories.insert(0, _selectedCategory);
      }
      
      if (!_statuses.contains(_selectedStatus)) {
        _statuses.insert(0, _selectedStatus);
      }
    }

    if (widget.property != null) {
      _loadExistingImages();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingImages() async {
    final id = widget.property?.id;
    if (id == null || id == 0) return;
    setState(() => _loadingImages = true);
    try {
      final response = await _propertyService.getPropertyDetail(id);
      if (response.statusCode == 200) {
        final detail = _propertyService.parsePropertyDetail(response.body);
        setState(() => _existingImages = detail.gallery);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingImages = false);
  }

  Future<void> _deleteExistingImage(PropertyGalleryItem image) async {
    if (image.id == 0) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Gambar'),
        content: const Text('Gambar ini akan dihapus permanen dari server. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deletingImageIds.add(image.id));
    final response = await _service.deleteImage(image.id);
    setState(() => _deletingImageIds.remove(image.id));

    if (!mounted) return;
    if (response.statusCode == 200) {
      setState(() => _existingImages.removeWhere((i) => i.id == image.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar berhasil dihapus')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_service.parseMessage(response.body))),
      );
    }
  }

  Future<void> _pickFiles() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        List<SelectedImage> newImages = [];
        for (var file in images) {
          final bytes = await file.readAsBytes();
          // basic 5MB check
          if (bytes.lengthInBytes <= 5 * 1024 * 1024) {
            newImages.add(SelectedImage(file, bytes));
          }
        }
        
        setState(() {
          _selectedFiles.addAll(newImages);
          if (_selectedFiles.length > 10) {
            _selectedFiles = _selectedFiles.sublist(0, 10);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maksimal 10 foto diperbolehkan.')),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final p = AdminPropertyModel(
        id: widget.property?.id ?? 0,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : 'Klaten',
        price: double.parse(_priceController.text),
        status: _selectedStatus,
      );

      final response = widget.property == null
          ? await _service.createProperty(p)
          : await _service.updateProperty(p);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Image Upload
        if (_selectedFiles.isNotEmpty) {
          int propId = widget.property?.id ?? 0;
          if (propId == 0) {
            try {
              final Map<String, dynamic> body = jsonDecode(response.body);
              if (body['property'] != null && body['property']['id'] != null) {
                propId = body['property']['id'] is int 
                  ? body['property']['id'] 
                  : int.tryParse(body['property']['id'].toString()) ?? 0;
              }
            } catch (_) {}
          }
          
          if (propId > 0) {
             final filesData = _selectedFiles.map((f) => f.bytes.toList()).toList();
             final fileNames = _selectedFiles.map((f) => f.file.name).toList();
             await _service.uploadPropertyImages(propId, filesData, fileNames);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.property == null ? 'Properti Berhasil Ditambahkan' : 'Properti Berhasil Diperbarui')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_service.parseMessage(response.body))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Form
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BragaPageHeader(
                      title: widget.property == null ? 'Tambah Properti' : 'Edit Properti',
                      subtitle: 'Isi detail informasi utama untuk aset properti.',
                      onBack: () => Navigator.maybePop(context),
                      decorativeIcon: Icons.add_home_work_rounded,
                    ),
                    const SizedBox(height: 16),
                    
                    // Basic Info Card
                    _buildCard(
                      'Informasi Utama',
                      Icons.home_outlined,
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Judul Properti *', _titleController)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDropdown('Kategori *', _selectedCategory, _categories, (val) => setState(()=> _selectedCategory = val!))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Lokasi *', _locationController)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField('Harga (Rp) *', _priceController, isNumber: true)),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sidebar (Photos + Summary)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCard(
                      'Galeri Foto',
                      Icons.photo_camera_outlined,
                      Column(
                        children: [
                          InkWell(
                            onTap: _pickFiles,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade50,
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Klik untuk upload foto', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (widget.property != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gambar tersimpan', 
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                                ),
                                const SizedBox(height: 8),
                                if (_loadingImages)
                                  const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
                                if (!_loadingImages && _existingImages.isEmpty)
                                  const Text('Belum ada gambar tersimpan.', style: TextStyle(color: Colors.grey)),
                                if (_existingImages.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _existingImages.map((image) {
                                      final isDeleting = _deletingImageIds.contains(image.id);
                                      return SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                image.imageUrl,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) => Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                            if (isDeleting)
                                              Positioned.fill(
                                                child: Container(
                                                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                                                  child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                                                ),
                                              ),
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: InkWell(
                                                onTap: isDeleting ? null : () => _deleteExistingImage(image),
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          const SizedBox(height: 16),
                          if (_selectedFiles.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedFiles.map((f) => Stack(
                                children: [
                                  Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(image: MemoryImage(f.bytes), fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0, top: 0,
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedFiles.remove(f)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 16, color: Colors.red),
                                      ),
                                    ),
                                  )
                                ],
                              )).toList(),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildCard(
                      'Ringkasan Properti',
                      Icons.summarize_outlined,
                      Column(
                        children: [
                          _buildSummaryRow('Judul', _titleController.text.isNotEmpty ? _titleController.text : '-'),
                          _buildSummaryRow('Kategori', _selectedCategory),
                          _buildSummaryRow('Harga', _priceController.text.isNotEmpty ? 'Rp ${_priceController.text}' : '-'),
                          _buildSummaryRow('Status', _selectedStatus),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitForm,
                      icon: _isSubmitting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                          : const Icon(Icons.save),
                      label: Text(widget.property == null ? 'Tambah Properti' : 'Simpan Perubahan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4670D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFF6EC), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: const Color(0xFFC4670D), size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC4670D))),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC4670D))),
      ),
      items: items.map((e) {
        String displayText = e;
        if (e == 'available') displayText = 'Tersedia';
        if (e == 'booking') displayText = 'Sedang Dibooking';
        if (e == 'sold') displayText = 'Terjual';
        return DropdownMenuItem(value: e, child: Text(displayText));
      }).toList(),
      onChanged: (val) {
        onChanged(val);
        setState(() {});
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
