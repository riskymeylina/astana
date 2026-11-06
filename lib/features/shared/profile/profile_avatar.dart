import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';

class ProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final bool isEditable;
  final VoidCallback? onUploadSuccess;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.initials = 'U',
    this.size = 72,
    this.isEditable = false,
    this.onUploadSuccess,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (picked == null) return;

      setState(() {
        _isUploading = true;
      });

      final response = await _authService.uploadProfilePhoto(picked);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui.'),
              backgroundColor: Color(0xFF8E4E16),
            ),
          );
        }
        widget.onUploadSuccess?.call();
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                body['message'] ?? 'Gagal mengunggah foto profil.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat mengunggah foto.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF8E4E16)),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded, color: Color(0xFF8E4E16)),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFE9C9),
      ),
      child: ClipOval(
        child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
            ? Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );

    if (!widget.isEditable) {
      return avatarWidget;
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _showSourceSheet,
          child: avatarWidget,
        ),
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black45,
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _showSourceSheet,
            child: Container(
              width: widget.size * 0.32,
              height: widget.size * 0.32,
              decoration: BoxDecoration(
                color: const Color(0xFF8E4E16),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: widget.size * 0.16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF7E5CB),
      alignment: Alignment.center,
      child: Text(
        widget.initials,
        style: TextStyle(
          fontSize: widget.size * 0.4,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF8E4E16),
        ),
      ),
    );
  }
}
