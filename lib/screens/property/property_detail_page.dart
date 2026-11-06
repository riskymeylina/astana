import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/auth_service.dart';
import '../../services/app_config.dart';

class PropertyDetailPage extends StatefulWidget {
  const PropertyDetailPage({super.key, required this.propertyId});

  final int propertyId;

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  final PropertyService _propertyService = PropertyService();

  PropertyModel? _property;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPropertyDetail();
  }

  Future<void> _loadPropertyDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _propertyService.getPropertyDetail(
        widget.propertyId,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _errorMessage = _propertyService.parseMessage(response.body);
          _isLoading = false;
        });
        return;
      }

      final property = _propertyService.parsePropertyDetail(response.body);

      setState(() {
        _property = property;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Gagal memuat detail properti';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _PropertyStateMessage(
                message: _errorMessage!,
                buttonLabel: 'Coba Lagi',
                onPressed: _loadPropertyDetail,
              )
            : _property == null
            ? _PropertyStateMessage(
                message: 'Properti tidak ditemukan',
                buttonLabel: 'Kembali',
                onPressed: () => Navigator.pop(context),
              )
            : _PropertyDetailContent(
                property: _property!,
                propertyService: _propertyService,
              ),
      ),
    );
  }
}

class _PropertyDetailContent extends StatelessWidget {
  const _PropertyDetailContent({
    required this.property,
    required this.propertyService,
  });

  final PropertyModel property;
  final PropertyService propertyService;

  List<_GalleryItem> get _galleryItems {
    final fromApi = property.gallery
        .where((item) => item.imageUrl.trim().isNotEmpty)
        .toList();

    final mappedFromApi = fromApi
        .asMap()
        .entries
        .map(
          (entry) {
            String rawUrl = entry.value.imageUrl.trim();
            if (rawUrl.startsWith('/uploads')) {
              rawUrl = '${AppConfig.serverBaseUrl}$rawUrl';
            }
            if (rawUrl.contains(' ')) {
              rawUrl = Uri.encodeFull(rawUrl);
            }

            final isNetwork = rawUrl.startsWith('http://') || rawUrl.startsWith('https://');
            return _GalleryItem(
              source: rawUrl,
              assetPath: isNetwork
                  ? null
                  : _resolveGalleryAssetPath(
                      entry.value.title,
                      entry.value.subtitle,
                      entry.key,
                    ),
              title: _resolveGalleryTitle(entry.value, entry.key),
              subtitle: _resolveGallerySubtitle(entry.value),
              details: entry.value.details.isNotEmpty
                  ? entry.value.details
                  : const ['Detail belum tersedia'],
            );
          },
        )
        .toList();

    if (mappedFromApi.isNotEmpty) {
      return mappedFromApi;
    }

    return [
      const _GalleryItem(
        source: '',
        assetPath: 'assets/images/home atas.jpg',
        title: 'Tampak Depan',
        subtitle: 'Visual utama properti',
        details: ['Silakan tambahkan data galeri di admin panel'],
      ),
    ];
  }

  void _openFullScreenGallery(BuildContext context, int initialIndex) {
    final items = _galleryItems;
    if (items.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: PhotoViewGallery.builder(
                  itemCount: items.length,
                  pageController: PageController(initialPage: initialIndex),
                  builder: (context, index) {
                    final item = items[index];
                    return PhotoViewGalleryPageOptions(
                      imageProvider: item.imageProvider,
                      heroAttributes: PhotoViewHeroAttributes(
                        tag: '${item.source}-$index',
                      ),
                    );
                  },
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF1E2B5B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerImage() {
    final items = _galleryItems;
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        height: 340,
        color: const Color(0xFFEADCCB),
        child: const Icon(Icons.image_not_supported_rounded, size: 48),
      );
    }
    final mainItem = items.first;
    if (mainItem.assetPath != null) {
      return Image.asset(
        mainItem.assetPath!,
        width: double.infinity,
        height: 340,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: double.infinity,
          height: 340,
          color: const Color(0xFFEADCCB),
          child: const Icon(Icons.image_not_supported_rounded, size: 48),
        ),
      );
    }

    // Try network image with fallback to local asset if available
    final fallbackAsset = _resolveFallbackAsset(mainItem.source, mainItem.title);

    if (kIsWeb) {
      return Image.network(
        mainItem.source,
        width: double.infinity,
        height: 340,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          if (fallbackAsset != null) {
            return Image.asset(
              fallbackAsset,
              width: double.infinity,
              height: 340,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: double.infinity,
                height: 340,
                color: const Color(0xFFEADCCB),
                child: const Icon(Icons.image_not_supported_rounded, size: 48),
              ),
            );
          }
          return Container(
            width: double.infinity,
            height: 340,
            color: const Color(0xFFEADCCB),
            child: const Icon(Icons.image_not_supported_rounded, size: 48),
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: mainItem.source,
      width: double.infinity,
      height: 340,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        width: double.infinity,
        height: 340,
        color: const Color(0xFFEADCCB),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      errorWidget: (_, _, _) {
        if (fallbackAsset != null) {
          return Image.asset(
            fallbackAsset,
            width: double.infinity,
            height: 340,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: double.infinity,
              height: 340,
              color: const Color(0xFFEADCCB),
              child: const Icon(Icons.image_not_supported_rounded, size: 48),
            ),
          );
        }
        return Container(
          width: double.infinity,
          height: 340,
          color: const Color(0xFFEADCCB),
          child: const Icon(Icons.image_not_supported_rounded, size: 48),
        );
      },
    );
  }

  static String? _resolveFallbackAsset(String source, String title) {
    // If the filename matches any local asset in assets/images/
    try {
      final uri = Uri.parse(source);
      final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (filename.isNotEmpty) {
        final decoded = Uri.decodeComponent(filename);
        return 'assets/images/$decoded';
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final role = (AuthService().getSession()?['role'] ?? '').toString().toLowerCase();
    final isBuyer = role == UserRoles.pembeli;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(bottom: isBuyer ? 100 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        final items = _galleryItems;
                        if (items.isEmpty) return;
                        final mainItem = items.first;
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            insetPadding: EdgeInsets.zero,
                            backgroundColor: Colors.black,
                            child: PhotoView(
                              imageProvider: mainItem.imageProvider,
                              backgroundDecoration: const BoxDecoration(color: Colors.black),
                            ),
                          ),
                        );
                      },
                      child: _buildBannerImage(),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _CircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF33241A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.place_rounded,
                                      size: 16,
                                      color: Color(0xFF6D5540),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        property.location,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6D5540),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5C1E04), // brown
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  propertyService.formatPrice(property.price),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  'Harga jual',
                                  style: TextStyle(
                                    color: Color(0xFFFFEEDB), // cream
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatusChip(label: property.statusLabel),
                      const SizedBox(height: 20),
                      const Text(
                        'Gallery',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF33241A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _galleryItems.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final galleryItem = _galleryItems[index];

                            return _GalleryThumbnail(
                              item: galleryItem,
                              onTap: () => _openFullScreenGallery(context, index),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isBuyer)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (property.status.toLowerCase() == 'sold' ||
                              property.status.toLowerCase() == 'terjual' ||
                              property.status.toLowerCase() == 'booking' ||
                              property.status.toLowerCase() == 'sedang dibooking' ||
                              property.status.toLowerCase() == 'archived')
                      ? null
                      : () => _showPurchaseConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C1E04), // dark brown
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Pesan Properti',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showPurchaseConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final width = MediaQuery.sizeOf(dialogContext).width;
        final dialogWidth = width > 520 ? 440.0 : width - 32;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8C9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(0xFF8E4E16),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Konfirmasi Pemesanan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF33241A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Apakah Anda yakin ingin memesan properti ini?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6D5540),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6EC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8CFB0)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: property.gallery.isNotEmpty ? property.gallery.first.imageUrl : '',
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              width: 54,
                              height: 54,
                              color: const Color(0xFFEADCCB),
                            ),
                            errorWidget: (_, _, _) => Container(
                              width: 54,
                              height: 54,
                              color: const Color(0xFFEADCCB),
                              child: const Icon(
                                Icons.home_work_rounded,
                                color: Color(0xFF8E4E16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF33241A),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                propertyService.formatPrice(property.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8E4E16),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;
                      final cancelButton = OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5E3210),
                          side: const BorderSide(color: Color(0xFFE0C4A0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      );
                      final confirmButton = ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C1E04),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Pesan Sekarang',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: confirmButton,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: cancelButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cancelButton),
                          const SizedBox(width: 10),
                          Expanded(child: confirmButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    Navigator.pushNamed(
      context,
      '/purchase-form',
      arguments: {
        'propertyId': property.id,
        'propertyTitle': property.title,
        'propertyPrice': property.price,
      },
    );
  }

}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isBooking = label.toLowerCase().contains('booking');
    final isSold = label.toLowerCase().contains('jual');
    final backgroundColor = isSold
        ? const Color(0xFFE7D8CF)
        : isBooking
        ? const Color(0xFFFFE7C2)
        : const Color(0xFFDDF0D8);
    final textColor = isSold
        ? const Color(0xFF7A4D3A)
        : isBooking
        ? const Color(0xFF8E4E16)
        : const Color(0xFF2D6A30);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryItem {
  const _GalleryItem({
    required this.source,
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.details,
  });

  final String source;
  final String? assetPath;
  final String title;
  final String subtitle;
  final List<String> details;

  ImageProvider get imageProvider {
    final asset = assetPath;
    if (asset != null) {
      return AssetImage(asset);
    }
    if (kIsWeb) {
      return NetworkImage(source);
    }
    return CachedNetworkImageProvider(source);
  }
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({required this.item, required this.onTap});

  final _GalleryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (item.assetPath != null) {
      imageWidget = Image.asset(
        item.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.image_rounded,
          color: Color(0xFF8B8277),
        ),
      );
    } else {
      String? fallbackAsset;
      try {
        final uri = Uri.parse(item.source);
        final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (filename.isNotEmpty) {
          fallbackAsset = 'assets/images/${Uri.decodeComponent(filename)}';
        }
      } catch (_) {}

      if (kIsWeb) {
        imageWidget = Image.network(
          item.source,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            if (fallbackAsset != null) {
              return Image.asset(
                fallbackAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_rounded,
                  color: Color(0xFF8B8277),
                ),
              );
            }
            return const Icon(Icons.image_rounded, color: Color(0xFF8B8277));
          },
        );
      } else {
        imageWidget = CachedNetworkImage(
          imageUrl: item.source,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            color: const Color(0xFFEAE5DD),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, _, _) {
            if (fallbackAsset != null) {
              return Image.asset(
                fallbackAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_rounded,
                  color: Color(0xFF8B8277),
                ),
              );
            }
            return const Icon(Icons.image_rounded, color: Color(0xFF8B8277));
          },
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 88,
            height: 88,
            color: const Color(0xFFEAE5DD),
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}

extension _PropertyGalleryAssets on _PropertyDetailContent {
  String _resolveGalleryTitle(PropertyGalleryItem item, int index) {
    final normalized = '${item.title} ${item.subtitle}'.toLowerCase();

    if (normalized.contains('kamar mandi')) {
      return 'Kamar Mandi';
    }

    if (normalized.contains('dapur')) {
      return 'Dapur';
    }

    if (normalized.contains('ruang keluarga') ||
        normalized.contains('keluarga')) {
      return 'Ruang Keluarga';
    }

    if (normalized.contains('ruang tamu')) {
      return 'Ruang Tamu';
    }

    if (normalized.contains('kamar tidur')) {
      if (normalized.contains('2') || index == 2) {
        return 'Kamar Tidur 2';
      }

      if (normalized.contains('utama') || index == 1) {
        return 'Kamar Tidur 1';
      }

      return 'Kamar Tidur';
    }

    if (normalized.contains('halaman') || normalized.contains('taman')) {
      return 'Halaman';
    }

    if (normalized.contains('tampak depan') ||
        normalized.contains('tampilan depan') ||
        normalized.contains('eksterior')) {
      return 'Tampak Depan';
    }

    return item.title.isNotEmpty ? item.title : 'Gallery Properti';
  }

  String _resolveGallerySubtitle(PropertyGalleryItem item) {
    final normalized = '${item.title} ${item.subtitle}'.toLowerCase();

    if (normalized.contains('kamar tidur')) {
      return 'Area istirahat yang sesuai dengan aset ruangan';
    }

    if (normalized.contains('kamar mandi')) {
      return 'Ruang mandi sesuai data properti';
    }

    if (normalized.contains('dapur')) {
      return 'Area memasak sesuai data properti';
    }

    if (normalized.contains('ruang keluarga')) {
      return 'Area kumpul keluarga yang lebih lega';
    }

    if (normalized.contains('ruang tamu')) {
      return 'Area menerima tamu dan bersantai';
    }

    if (normalized.contains('tampak depan') ||
        normalized.contains('tampilan depan') ||
        normalized.contains('eksterior')) {
      return 'Visual utama properti';
    }

    return item.subtitle.isNotEmpty ? item.subtitle : 'Detail visual properti';
  }

  String? _resolveGalleryAssetPath(
    String title,
    String subtitle,
    int index,
  ) {
    final normalized = '$title $subtitle'.toLowerCase();

    if (normalized.contains('tampak depan') ||
        normalized.contains('tampilan depan') ||
        normalized.contains('eksterior')) {
      return 'assets/images/home atas.jpg';
    }

    if (normalized.contains('kamar mandi')) {
      return 'assets/images/kamar mandi.jpg';
    }

    if (normalized.contains('dapur')) {
      return 'assets/images/dapur.jpg';
    }

    if (normalized.contains('ruang keluarga') ||
        normalized.contains('keluarga')) {
      return 'assets/images/ruang eluarga.jpg';
    }

    if (normalized.contains('ruang tamu')) {
      return 'assets/images/ruang tamu.jpg';
    }

    if (normalized.contains('halaman') || normalized.contains('taman')) {
      return 'assets/images/home.jpg';
    }

    if (normalized.contains('kamar tidur')) {
      if (normalized.contains('2') || index == 3 || index % 2 == 1) {
        return 'assets/images/kamar tidur 2.jpg';
      }

      if (normalized.contains('1') || index == 2) {
        return 'assets/images/kamar tidur 1.jpg';
      }


      return 'assets/images/kamar tidur 1.jpg';
    }

    if (normalized.contains('interior')) {
      switch (index) {
        case 1:
          return 'assets/images/ruang tamu.jpg';
        case 2:
          return 'assets/images/kamar tidur 1.jpg';
        case 3:
          return 'assets/images/kamar tidur 2.jpg';
        case 4:
          return 'assets/images/dapur.jpg';
        case 5:
          return 'assets/images/kamar mandi.jpg';
        case 6:
          return 'assets/images/ruang eluarga.jpg';
        default:
          return 'assets/images/ruang tamu.jpg';
      }
    }

    switch (index) {
      case 0:
        return 'assets/images/home atas.jpg';
      case 1:
        return 'assets/images/ruang tamu.jpg';
      case 2:
        return 'assets/images/kamar tidur 1.jpg';
      case 3:
        return 'assets/images/kamar tidur 2.jpg';
      case 4:
        return 'assets/images/dapur.jpg';
      case 5:
        return 'assets/images/kamar mandi.jpg';
      case 6:
        return 'assets/images/ruang eluarga.jpg';
      default:
        return 'assets/images/home.jpg';
    }
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: const Color(0xFF1E2B5B)),
      ),
    );
  }
}

class _PropertyStateMessage extends StatelessWidget {
  const _PropertyStateMessage({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.home_work_rounded,
              size: 48,
              color: Color(0xFF8E4E16),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF574332),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2B5B),
                foregroundColor: Colors.white,
              ),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
