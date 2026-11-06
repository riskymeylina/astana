import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/property_filter_sheet.dart';
import '../../widgets/bottom_nav_section.dart';
import '../../widgets/home/home_cards.dart';
import '../../widgets/home/home_menu_widgets.dart';
import '../../features/buyer/profile/buyer_profile_page.dart';
import '../../features/staff/profile/staff_profile_page.dart';
import '../../features/admin/profile/admin_profile_page.dart';
import '../admin/dashboard/web_dashboard_scaffold.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final PropertyService _propertyService = PropertyService();
  final NotificationService _notificationSvc = NotificationService();
  final PageController _promoController = PageController(
    viewportFraction: 0.87,
  );
  final TextEditingController _homeSearchController = TextEditingController();
  final TextEditingController _exploreSearchController =
      TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _promoTimer;
  bool _isPromoUserInteracting = false;

  late int _selectedNavIndex = widget.initialIndex;
  int _activePromoIndex = 0;
  int _unreadNotificationCount = 0;
  late String _userName = (AuthService().getSession()?['name'] ?? 'Pengguna').toString();
  late String _userRole = UserRoles.normalize(AuthService().getSession()?['role']?.toString());
  String _userLocation = 'Mendeteksi lokasi...';
  bool _isSessionVerified = false;
  bool _isLoadingProperties = true;
  String? _propertyErrorMessage;
  List<PropertyModel> _featuredProperties = const [];
  List<PropertyModel> _properties = const [];

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final response = await _notificationSvc.getNotifications();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = _notificationSvc.parseNotifications(response.body);
        final unread = list.where((n) => !n.isRead).length;
        if (mounted) {
          setState(() {
            _unreadNotificationCount = unread;
          });
        }
      }
    } catch (_) {}
  }


  void _openPropertyDetail(PropertyModel property) {
    Navigator.pushNamed(context, '/property-detail', arguments: property.id);
  }

  Future<void> _loadProperties() async {
    _stopPromoAutoScroll();

    if (mounted) {
      setState(() {
        _isLoadingProperties = true;
        _propertyErrorMessage = null;
      });
    }

    final response = await _propertyService.getProperties();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (!mounted) return;
      setState(() {
        _propertyErrorMessage = _propertyService.parseMessage(response.body);
        _isLoadingProperties = false;
      });
      return;
    }

    final properties = _propertyService.parseProperties(response.body);

    if (!mounted) return;
    setState(() {
      _properties = properties;
      _featuredProperties = properties;
      _activePromoIndex = 0;
      _isLoadingProperties = false;
    });
    _loadUnreadNotificationCount();
    _syncPromoAutoScroll();
  }



  void _openPropertySearch({
    String? query,
    String? brand,
    int? minPrice,
    int? maxPrice,
    String? status,
    String? sortBy,
    String title = 'Cari Properti',
  }) {
    Navigator.pushNamed(
      context,
      '/property-search',
      arguments: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (status != null) 'status': status,
        if (sortBy != null) 'sortBy': sortBy,
        'title': title,
      },
    );
  }

  bool get _shouldAutoScrollPromo =>
      mounted &&
      _selectedNavIndex == 0 &&
      !_isPromoUserInteracting &&
      _featuredProperties.length > 1;

  void _stopPromoAutoScroll() {
    _promoTimer?.cancel();
    _promoTimer = null;
  }

  void _syncPromoAutoScroll() {
    _stopPromoAutoScroll();
    if (!_shouldAutoScrollPromo) {
      return;
    }
    _startPromoAutoScroll();
  }

  void _setPromoUserInteracting(bool value) {
    if (_isPromoUserInteracting == value) {
      return;
    }
    _isPromoUserInteracting = value;
    _syncPromoAutoScroll();
  }

  void _handleBottomNavTap(int index) {
    if (!mounted) {
      return;
    }

    // index 2 = consultation (via FAB overlay, not used here anymore)
    // index 4 = notifications (navigate without changing tab)
    if (index == 4) {
      Navigator.pushNamed(context, '/notifications').then((_) {
        _loadUnreadNotificationCount();
      });
      return;
    }

    setState(() => _selectedNavIndex = index);
    _syncPromoAutoScroll();
  }

  void _handlePromoPageChanged(int index) {
    if (!mounted) {
      return;
    }
    final safeIndex = _featuredProperties.isEmpty
        ? 0
        : index % _featuredProperties.length;
    setState(() => _activePromoIndex = safeIndex);
  }

  bool _handlePromoScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _setPromoUserInteracting(true);
    } else if (notification is ScrollEndNotification) {
      _setPromoUserInteracting(false);
    }
    return false;
  }

  void _advancePromoPage() {
    if (!mounted ||
        !_promoController.hasClients ||
        _featuredProperties.length < 2) {
      return;
    }

    if (_activePromoIndex >= _featuredProperties.length) {
      _activePromoIndex = 0;
    }

    final next = (_activePromoIndex + 1) % _featuredProperties.length;
    _promoController.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _startPromoAutoScroll() {
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_shouldAutoScrollPromo || !_promoController.hasClients) {
        return;
      }
      _advancePromoPage();
    });
  }



  @override
  void initState() {
    super.initState();
    _checkSessionAndLoadUser();
    _loadCurrentLocation();
    _loadProperties();
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    _stopPromoAutoScroll();
    _homeSearchController.dispose();
    _exploreSearchController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _userLocation = 'Layanan lokasi nonaktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _userLocation = 'Izin lokasi ditolak');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _userLocation = 'Izin lokasi ditolak permanen');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final resolvedLocation = await _resolveLocationLabel(position);

      if (!mounted) return;
      setState(() => _userLocation = resolvedLocation);
    } catch (_) {
      if (!mounted) return;
      setState(() => _userLocation = 'Lokasi tidak tersedia');
    }
  }

  Future<String> _resolveLocationLabel(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final area = (place.subLocality ?? place.locality ?? '').trim();
        final city = (place.locality ?? place.subAdministrativeArea ?? '')
            .trim();
        final province = (place.administrativeArea ?? '').trim();

        final parts = <String>[];
        if (area.isNotEmpty) parts.add(area);
        if (city.isNotEmpty && city != area) parts.add(city);
        if (province.isNotEmpty && province != city) parts.add(province);

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {
      if (!kIsWeb) {
        return 'Lokasi pengguna';
      }
    }

    if (kIsWeb) {
      final osmLocation = await _resolveLocationFromOpenStreetMap(position);
      if (osmLocation != null) {
        return osmLocation;
      }

      return 'Koordinat ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    }

    return 'Lokasi pengguna';
  }

  Future<String?> _resolveLocationFromOpenStreetMap(Position position) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'zoom': '10',
        'addressdetails': '1',
      });

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final address = decoded['address'];
      if (address is! Map) {
        return null;
      }

      final normalizedAddress = Map<String, dynamic>.from(address);
      final city =
          (normalizedAddress['city'] ??
                  normalizedAddress['town'] ??
                  normalizedAddress['municipality'] ??
                  normalizedAddress['county'] ??
                  normalizedAddress['state_district'] ??
                  '')
              .toString()
              .trim();
      final province = (normalizedAddress['state'] ?? '').toString().trim();

      final parts = <String>[];
      if (city.isNotEmpty) parts.add(city);
      if (province.isNotEmpty && province != city) parts.add(province);

      if (parts.isEmpty) {
        return null;
      }

      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> _retryLoadLocation() async {
    if (!mounted) return;
    setState(() => _userLocation = 'Mendeteksi lokasi...');
    await _loadCurrentLocation();
  }

  Future<void> _openBrowserLocationSettings() async {
    if (!kIsWeb) return;

    final settingsUri = Uri.parse('chrome://settings/content/location');
    final launched = await launchUrl(settingsUri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izinkan akses lokasi pada browser lalu coba lagi.'),
        ),
      );
    }
  }

  void _handleLocationTap() {
    if (_userLocation == 'Izin lokasi ditolak' ||
        _userLocation == 'Izin lokasi ditolak permanen') {
      _openBrowserLocationSettings();
      return;
    }

    _retryLoadLocation();
  }

  String get _locationHintText {
    if (_userLocation == 'Izin lokasi ditolak' ||
        _userLocation == 'Izin lokasi ditolak permanen') {
      return kIsWeb
          ? '$_userLocation • Tap untuk cek izin browser'
          : '$_userLocation • Tap untuk coba lagi';
    }

    return _userLocation;
  }

  Color get _locationHintColor {
    if (_userLocation == 'Izin lokasi ditolak' ||
        _userLocation == 'Izin lokasi ditolak permanen') {
      return const Color(0xFF9C3F1C);
    }

    return const Color(0xFF6D5540);
  }

  FontWeight get _locationHintWeight {
    if (_userLocation == 'Izin lokasi ditolak' ||
        _userLocation == 'Izin lokasi ditolak permanen') {
      return FontWeight.w700;
    }

    return FontWeight.w500;
  }

  TextDecoration get _locationHintDecoration {
    if (_userLocation == 'Izin lokasi ditolak' ||
        _userLocation == 'Izin lokasi ditolak permanen') {
      return TextDecoration.underline;
    }

    return TextDecoration.none;
  }

  MouseCursor get _locationCursor => SystemMouseCursors.click;

  Future<void> _checkSessionAndLoadUser() async {
    final session = await _authService.restoreSession();

    if (session == null || (session['token'] ?? '').toString().isEmpty) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login atau daftar terlebih dahulu.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    final resolvedRole = UserRoles.normalize(session['role']?.toString());
    final resolvedName = (session['name'] ?? 'Pengguna').toString();
    final resolvedVerified =
        (session['sessionState'] ?? '').toString() == SessionState.verified;

    if (!mounted) return;

    // Jika web dan role admin/staf, langsung redirect ke WebDashboardScaffold
    // tanpa menunggu rebuild berikutnya supaya tidak sekilas tampil mobile view.
    if (kIsWeb &&
        (resolvedRole == UserRoles.admin || resolvedRole == UserRoles.staf)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return;
    }

    setState(() {
      _userName = resolvedName;
      _userRole = resolvedRole;
      _isSessionVerified = resolvedVerified;
    });
  }

  bool get _isMarketing => _userRole == UserRoles.staf;
  bool get _isAdmin => _userRole == UserRoles.admin;
  bool get _useSidebarNavigation =>
      kIsWeb && (_isAdmin || _isMarketing);

  void _goToRoute(String route) {
    if (route == '/home') {
      setState(() => _selectedNavIndex = 0);
      return;
    }
    Navigator.pushNamed(context, route).then((_) {
      _loadUnreadNotificationCount();
    });
  }

  void _openSideMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _handleDrawerTap(String key) async {
    Navigator.pop(context);

    if (!mounted) return;

    switch (key) {
      case 'beranda':
        setState(() => _selectedNavIndex = 0);
        return;
      case 'promo':
        _goToRoute('/promo-properti');
        return;
      case 'profile':
        setState(() => _selectedNavIndex = 3);
        return;
      case 'lokasi':
        setState(() => _selectedNavIndex = 1);
        return;
      case 'konsultasi':
        _goToRoute('/consultation');
        return;
      case 'notification':
        _goToRoute('/notifications');
        return;
      case 'logout':
        await _authService.clearSession();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
    }
  }

  void _showFilterSheet() async {
    final result = await PropertyFilterSheet.show(
      context,
    );

    if (result != null && mounted) {
      _openPropertySearch(
        query: _homeSearchController.text,
        minPrice: result['minPrice'] as int?,
        maxPrice: result['maxPrice'] as int?,
        status: result['status'] as String?,
        sortBy: result['sortBy'] as String?,
        title: 'Hasil Filter',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useSidebarNavigation) {
      // Need to import WebDashboardScaffold at the top of the file
      return WebDashboardScaffold(initialIndex: _selectedNavIndex);
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFFF6EC),
      // Always provide the side menu drawer so the menu button can open it.
      drawer: _buildSideMenuDrawer(),
      body: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            children: [
              if (!_isSessionVerified)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: const Color(0xFFFFE7C2),
                  child: const Text(
                    'Anda sedang memakai sesi cache. Sambungkan ke server untuk membuka fitur sensitif.',
                    style: TextStyle(
                      color: Color(0xFF7A4B16),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(child: _buildCurrentTabBody()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _useSidebarNavigation
          ? null
          : BottomNavSection(
              currentIndex: _selectedNavIndex,
              onTap: _handleBottomNavTap,
              notificationCount: _unreadNotificationCount,
            ),
    );
  }

  Widget _buildCurrentTabBody() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildExploreTab();
      case 2:
        return _buildRoleTabThree();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    // Harga terjangkau = properties with price <= 600 million
    final affordableProperties = _properties
        .where((p) => p.price <= 600000000)
        .take(4)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopHeader(),
          const SizedBox(height: 12),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildHeroBanner(),
          const SizedBox(height: 20),

          // ── Properti Unggulan ──
          _buildSectionHeaderWithAction(
            title: 'Properti Unggulan',
            onAction: () => _openPropertySearch(
              title: 'Properti Unggulan',
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingProperties)
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_propertyErrorMessage != null)
            HomePropertyStateCard(
              message: _propertyErrorMessage!,
              buttonLabel: 'Coba Lagi',
              onPressed: _loadProperties,
            )
          else if (_featuredProperties.isEmpty)
            HomePropertyStateCard(
              message: 'Belum ada properti unggulan dari backend.',
              buttonLabel: 'Muat Ulang',
              onPressed: _loadProperties,
            )
          else ...[
            SizedBox(
              height: 220,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handlePromoScrollNotification,
                child: PageView.builder(
                  controller: _promoController,
                  itemCount: _featuredProperties.length,
                  onPageChanged: _handlePromoPageChanged,
                  itemBuilder: (context, index) {
                    final promo = _featuredProperties[index];
                    return HomePromoCard(
                      property: promo,
                      priceLabel: _propertyService.formatPrice(promo.price),
                      onTap: () => _openPropertyDetail(promo),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_featuredProperties.length, (index) {
                final selected = _activePromoIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: selected ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: selected
                        ? const Color(0xFFB6651E)
                        : const Color(0xFFD9C3A8),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 20),

          // ── Harga Terjangkau ──
          _buildSectionHeaderWithAction(
            title: 'Harga Terjangkau',
            onAction: () => _openPropertySearch(
              maxPrice: 600000000,
              sortBy: 'price_low',
              title: 'Harga Terjangkau',
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingProperties)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_propertyErrorMessage != null)
            HomePropertyStateCard(
              message: _propertyErrorMessage!,
              buttonLabel: 'Coba Lagi',
              onPressed: _loadProperties,
            )
          else if (affordableProperties.isEmpty)
            HomePropertyStateCard(
              message: 'Belum ada properti harga terjangkau dari backend.',
              buttonLabel: 'Muat Ulang',
              onPressed: _loadProperties,
            )
          else
            HomePropertyGrid(
              properties: affordableProperties,
              propertyService: _propertyService,
              onTap: _openPropertyDetail,
            ),
        ],
      ),
    );
  }

  /// Builds a section header row with a "Lihat Semua" text button on the right.
  Widget _buildSectionHeaderWithAction({
    required String title,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F2318),
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFCB7D2A),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text(
            'Lihat Semua',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }



  Widget _buildRoleTabThree() {
    if (_isAdmin) {
      return HomeSimpleTabView(
        title: 'Laporan Global',
        subtitle:
            'Buat laporan penjualan, pemesanan, ketersediaan, serta invoice.',
        icon: Icons.analytics_rounded,
        buttonLabel: 'Buat Laporan',
        onPressed: () {
          Navigator.pushNamed(context, '/admin/reports/global');
        },
      );
    }

    if (_isMarketing) {
      return HomeSimpleTabView(
        title: 'Konfirmasi Survei',
        subtitle:
            'Setujui jadwal survei dan tindak lanjut konsultasi pelanggan.',
        icon: Icons.event_available_rounded,
        buttonLabel: 'Atur Jadwal',
        onPressed: () {
          Navigator.pushNamed(context, '/marketing-survey-requests');
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTopHeader() {
    final isBuyer = _userRole == UserRoles.pembeli;
    return Row(
      children: [
        if (!isBuyer) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF8B4F1F),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x338B4F1F),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _openSideMenu,
              icon: const Icon(Icons.menu_rounded, size: 20, color: Colors.white),
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD8B88A)),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.home_work_rounded),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PT ASTANA KARYA BANDAWASA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A2B1F),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 14,
                    color: Color(0xFF6D5540),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: MouseRegion(
                      cursor: _locationCursor,
                      child: GestureDetector(
                        onTap: _handleLocationTap,
                        child: Text(
                          _locationHintText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: _locationHintColor,
                            fontWeight: _locationHintWeight,
                            decoration: _locationHintDecoration,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: Color(0xFF2F2318),
        ),
        const SizedBox(width: 6),
        Text(
          _currentDateText,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2F2318),
          ),
        ),
      ],
    );
  }

  Widget _buildSideMenuDrawer() {
    return Drawer(
      width: 252,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA5622A), Color(0xFF8F4E1E), Color(0xFF6F3913)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    color: Color(0xFFFFEEDB),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                HomeMenuDrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  active: _selectedNavIndex == 0,
                  onTap: () => _handleDrawerTap('beranda'),
                ),
                HomeMenuDrawerItem(
                  icon: Icons.local_offer_rounded,
                  label: 'Promo Properti Saat Ini',
                  onTap: () => _handleDrawerTap('promo'),
                ),
                HomeMenuDrawerItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifikasi',
                  onTap: () => _handleDrawerTap('notification'),
                ),
                HomeMenuDrawerItem(
                  icon: Icons.forum_rounded,
                  label: 'Konsultasi',
                  active: _selectedNavIndex == 3,
                  onTap: () => _handleDrawerTap('konsultasi'),
                ),
                HomeMenuDrawerItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: _selectedNavIndex == 4,
                  onTap: () => _handleDrawerTap('profile'),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                const SizedBox(height: 10),
                HomeMenuDrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  onTap: () => _handleDrawerTap('logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8B88A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF6D5540)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _homeSearchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) =>
                  _openPropertySearch(query: value, title: 'Hasil Pencarian'),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Cari properti, lokasi, atau harga',
                hintStyle: TextStyle(fontSize: 14.5, color: Color(0xFF6D5540)),
              ),
              style: const TextStyle(fontSize: 14.5, color: Color(0xFF2F2318)),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _showFilterSheet,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: Color(0xFF6D5540),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        height: 198,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF8D4E18),
          image: const DecorationImage(
            image: AssetImage('assets/images/home.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xBE6D350E),
                    Color(0x9EC66B1B),
                    Color(0xA3D78829),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -24,
              top: -18,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -26,
              bottom: -45,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $_userName',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Waktu yang tepat untuk cari properti impian.\nPantau promo terbaru sekarang juga.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: Color(0xFFFFF4E4),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _goToRoute('/promo-properti'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF8D4E18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.local_offer_rounded, size: 18),
                        label: const Text('Promo Properti Saat Ini'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_isAdmin) {
      return const AdminProfilePage();
    }

    if (_isMarketing) {
      return const StaffProfilePage();
    }

    return const BuyerProfilePage();
  }


  String get _currentDateText {
    return DateFormat('d MMMM y', 'id_ID').format(DateTime.now());
  }

  Widget _buildExploreTab() {
    final featured = _featuredProperties;
    final exploreItems = _properties.isNotEmpty
        ? _properties
        : _featuredProperties;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Banner Card ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF5C1E04), Color(0xFF8F4E1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5C1E04).withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jelajah',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Temukan properti yang sesuai dengan kebutuhan Anda.',
                        style: TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.explore_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.08),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Search Bar with Filter Circle ──
          Container(
            height: 52,
            padding: const EdgeInsets.only(left: 16, right: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.black45),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _exploreSearchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => _openPropertySearch(
                      query: value,
                      title: 'Jelajah Properti',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Cari properti, lokasi, atau nama perumahan...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6E340B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Properti Unggulan Section ──
          _ExploreSectionHeader(
            title: 'Properti Unggulan',
            actionLabel: 'Lihat Semua',
            onActionTap: () => _openPropertySearch(
              title: 'Properti Unggulan',
            ),
          ),
          const SizedBox(height: 10),
          if (featured.isEmpty)
            HomePropertyStateCard(
              message: 'Belum ada properti unggulan dari backend.',
              buttonLabel: 'Muat Ulang',
              onPressed: _loadProperties,
            )
          else
            SizedBox(
              height: 256,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final property = featured[index];
                  return SizedBox(
                    width: MediaQuery.sizeOf(context).width - 72,
                    child: HomePromoCard(
                      property: property,
                      priceLabel: _propertyService.formatPrice(property.price),
                      onTap: () => _openPropertyDetail(property),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),

          // ── Harga Terjangkau Section ──
          _ExploreSectionHeader(
            title: 'Harga Terjangkau',
            actionLabel: 'Lihat Semua',
            onActionTap: () => _openPropertySearch(
              maxPrice: 500000000,
              title: 'Harga Terjangkau',
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingProperties)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_propertyErrorMessage != null)
            HomePropertyStateCard(
              message: _propertyErrorMessage!,
              buttonLabel: 'Coba Lagi',
              onPressed: _loadProperties,
            )
          else if (exploreItems.isEmpty)
            HomePropertyStateCard(
              message: 'Belum ada properti untuk ditampilkan.',
              buttonLabel: 'Muat Ulang',
              onPressed: _loadProperties,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exploreItems.length > 4 ? 4 : exploreItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final property = exploreItems[index];
                return _ExploreCompactPropertyCard(
                  property: property,
                  propertyService: _propertyService,
                  onTap: () => _openPropertyDetail(property),
                );
              },
            ),
        ],
      ),
    );
  }
}


class _ExploreSectionHeader extends StatelessWidget {
  const _ExploreSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2F2318),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFCB7D2A)),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ExploreFeaturedPropertyCard extends StatelessWidget {
  const _ExploreFeaturedPropertyCard({
    required this.property,
    required this.propertyService,
    required this.onTap,
  });

  final PropertyModel property;
  final PropertyService propertyService;
  final VoidCallback onTap;

  String get _imageUrl {
    if (property.gallery.isNotEmpty &&
        property.gallery.first.imageUrl.isNotEmpty) {
      return property.gallery.first.imageUrl;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF2EBE4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with stack
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: Image.network(
                      _imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFF0E0CF),
                      ),
                    ),
                  ),
                  // Category badge (white pill, left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        property.category.toLowerCase(),
                        style: const TextStyle(
                          color: Color(0xFF2F2318),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  // Featured badge (brown pill with gold star, right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E2F0D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF8C15A),
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            (property.id % 2 == 1) ? 'Featured' : 'New',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F2318),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Color(0xFF8E4E16),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF786351),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          propertyService.formatPrice(property.price),
                          style: const TextStyle(
                            color: Color(0xFFCB7D2A),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFECDDCC)),
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF6E340B),
                            size: 16,
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
      ),
    );
  }
}

class _ExploreCompactPropertyCard extends StatelessWidget {
  const _ExploreCompactPropertyCard({
    required this.property,
    required this.propertyService,
    required this.onTap,
  });

  final PropertyModel property;
  final PropertyService propertyService;
  final VoidCallback onTap;

  String get _imageUrl {
    if (property.gallery.isNotEmpty &&
        property.gallery.first.imageUrl.isNotEmpty) {
      return property.gallery.first.imageUrl;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    _imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF0E0CF),
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        color: Color(0xFF8E4E16),
                      ),
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
                        color: Color(0xFF2F2318),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      property.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF786351),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    propertyService.formatPrice(property.price),
                    style: const TextStyle(
                      color: Color(0xFFCB7D2A),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB28B62),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
