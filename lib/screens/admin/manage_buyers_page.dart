import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/admin_user_service.dart';
import '../../../services/admin_purchase_service.dart';
import '../../../models/admin_models.dart';
import '../../../models/purchase_order_model.dart';
import '../../../widgets/braga_page_header.dart';

class ManageBuyersPage extends StatefulWidget {
  const ManageBuyersPage({super.key});

  @override
  State<ManageBuyersPage> createState() => _ManageBuyersPageState();
}

class _ManageBuyersPageState extends State<ManageBuyersPage> {
  final AdminUserService _service = AdminUserService();
  final AdminPurchaseService _purchaseService = AdminPurchaseService();

  List<AdminUserModel> _users = [];
  List<PurchaseOrderModel> _bookings = [];
  bool _loading = true;
  String? _error;

  AdminUserModel? _selectedUser;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _itemsPerPage = 10;

  static const _amber = Color(0xFFFDD096);
  static const _border = Color(0xFFE7CCAE);
  static const _brown = Color(0xFF7A4F2D);

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.getUsers(role: 'pembeli');
      final bookingsRes = await _purchaseService.getBookings();
      if (res.statusCode == 200) {
        setState(() {
          _users = _service.parseUsers(res.body);
          if (bookingsRes.statusCode == 200) {
            _bookings = _purchaseService.parseBookings(bookingsRes.body);
          }
          if (_users.isNotEmpty) {
            _selectedUser = _users.first;
          }
          _loading = false;
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

  List<AdminUserModel> _getFilteredUsers() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((u) {
      return u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          (u.phone != null && u.phone!.toLowerCase().contains(query));
    }).toList();
  }

  void _showBuyerDetails(AdminUserModel user) {
    final userBookings = _bookings.where((b) => b.buyerUserId == user.id).toList();
    final purchasedProperties = userBookings
        .where((b) => b.status == 'confirmed')
        .map((b) => b.propertyTitle)
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _amber,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: _brown,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _brown,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (user.phone != null && user.phone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user.phone!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Transaksi',
                        '${userBookings.length}',
                        Icons.receipt_long_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Properti Dibeli',
                        '${purchasedProperties.length}',
                        Icons.home_work_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Properti yang Pernah Dibeli (Terkonfirmasi)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _brown,
                  ),
                ),
                const SizedBox(height: 8),
                if (purchasedProperties.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum ada properti dengan transaksi terkonfirmasi.',
                      style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...purchasedProperties.map(
                    (title) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Riwayat Lengkap Transaksi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _brown,
                  ),
                ),
                const SizedBox(height: 10),
                if (userBookings.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Belum ada riwayat transaksi.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: userBookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final b = userBookings[idx];
                      Color statusColor = Colors.grey;
                      String statusLabel = b.status;
                      switch (b.status) {
                        case 'pending_payment':
                          statusColor = Colors.orange;
                          statusLabel = 'Menunggu Pembayaran';
                          break;
                        case 'payment_uploaded':
                          statusColor = Colors.blue;
                          statusLabel = 'Menunggu Verifikasi';
                          break;
                        case 'payment_review':
                          statusColor = Colors.indigo;
                          statusLabel = 'Sedang Direview';
                          break;
                        case 'confirmed':
                          statusColor = Colors.green;
                          statusLabel = 'Terkonfirmasi';
                          break;
                        case 'rejected':
                          statusColor = Colors.red;
                          statusLabel = 'Ditolak';
                          break;
                        case 'cancelled':
                          statusColor = Colors.grey;
                          statusLabel = 'Dibatalkan';
                          break;
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    b.propertyTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Metode: ${b.paymentMethod}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  currencyFormat.format(b.paymentAmount > 0 ? b.paymentAmount : b.propertyPrice),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _brown),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _brown, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brown),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    if (filteredUsers.isNotEmpty) {
      if (_selectedUser == null || !filteredUsers.any((u) => u.id == _selectedUser!.id)) {
        _selectedUser = filteredUsers.first;
      }
    } else {
      _selectedUser = null;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Column(
        children: [
          BragaPageHeader(
            title: 'Manajemen Pembeli',
            subtitle: 'Kelola data seluruh pembeli.',
            decorativeIcon: Icons.people_rounded,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadUsers,
                tooltip: 'Muat ulang',
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 900) {
                            return _buildDesktopLayout(filteredUsers);
                          } else {
                            return _buildMobileLayout(filteredUsers);
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(List<AdminUserModel> filteredUsers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 380,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari nama, email atau nomor...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _brown),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: _border),
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? _buildEmpty()
                        : _buildLeftPaneList(filteredUsers),
                  ),
                  const Divider(height: 1, color: _border),
                  _buildLeftPanePagination(filteredUsers.length),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _selectedUser == null
                  ? const Center(
                      child: Text(
                        'Pilih pembeli untuk melihat detail',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : _buildRightPaneDetails(_selectedUser!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPaneList(List<AdminUserModel> filteredUsers) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final paginatedUsers = filteredUsers.sublist(
      startIndex,
      endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
    );

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: paginatedUsers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final user = paginatedUsers[idx];
        final isSelected = _selectedUser?.id == user.id;

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF2E6) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? _brown : _border),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedUser = user;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFDD096),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: _brown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSelected ? _brown : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isSelected ? _brown : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftPanePagination(int totalCount) {
    final totalPages = totalCount == 0 ? 1 : (totalCount / _itemsPerPage).ceil();
    final startIdx = totalCount == 0 ? 0 : (_currentPage - 1) * _itemsPerPage + 1;
    final endIdx = (_currentPage * _itemsPerPage) > totalCount ? totalCount : (_currentPage * _itemsPerPage);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _itemsPerPage,
                items: [5, 10, 20].map((count) {
                  return DropdownMenuItem<int>(
                    value: count,
                    child: Text('$count per hal.', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _itemsPerPage = val;
                      _currentPage = 1;
                    });
                  }
                },
              ),
            ),
          ),
          Text(
            '$startIdx - $endIdx dari $totalCount',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPageNavButton(
                icon: Icons.chevron_left_rounded,
                enabled: _currentPage > 1,
                onTap: () {
                  setState(() {
                    _currentPage--;
                  });
                },
              ),
              const SizedBox(width: 4),
              _buildPageNavButton(
                icon: Icons.chevron_right_rounded,
                enabled: _currentPage < totalPages,
                onTap: () {
                  setState(() {
                    _currentPage++;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: enabled ? _border : _border.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.black87 : Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildRightPaneDetails(AdminUserModel user) {
    final userBookings = _bookings.where((b) => b.buyerUserId == user.id).toList();
    final purchasedProperties = userBookings
        .where((b) => b.status == 'confirmed')
        .map((b) => b.propertyTitle)
        .toSet()
        .toList();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFFDD096),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _brown,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.phone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: _border),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDetailStatCard(
                  'Total Transaksi',
                  '${userBookings.length}',
                  Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailStatCard(
                  'Properti Dibeli',
                  '${purchasedProperties.length}',
                  Icons.home_work_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Properti yang Pernah Dibeli (Terkonfirmasi)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _brown,
            ),
          ),
          const SizedBox(height: 12),
          if (purchasedProperties.isEmpty)
            _buildEmptySectionPlaceholder(
              message: 'Belum ada properti dengan transaksi terkonfirmasi.',
              icon: Icons.home_rounded,
            )
          else
            ...purchasedProperties.map(
              (title) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 28),
          const Text(
            'Riwayat Lengkap Transaksi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _brown,
            ),
          ),
          const SizedBox(height: 12),
          if (userBookings.isEmpty)
            _buildEmptySectionPlaceholder(
              message: 'Belum ada riwayat transaksi.',
              icon: Icons.receipt_long_rounded,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userBookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final b = userBookings[idx];
                Color statusColor = Colors.grey;
                String statusLabel = b.status;
                switch (b.status) {
                  case 'pending_payment':
                    statusColor = Colors.orange;
                    statusLabel = 'Menunggu Pembayaran';
                    break;
                  case 'payment_uploaded':
                    statusColor = Colors.blue;
                    statusLabel = 'Menunggu Verifikasi';
                    break;
                  case 'payment_review':
                    statusColor = Colors.indigo;
                    statusLabel = 'Sedang Direview';
                    break;
                  case 'confirmed':
                    statusColor = Colors.green;
                    statusLabel = 'Terkonfirmasi';
                    break;
                  case 'rejected':
                    statusColor = Colors.red;
                    statusLabel = 'Ditolak';
                    break;
                  case 'cancelled':
                    statusColor = Colors.grey;
                    statusLabel = 'Dibatalkan';
                    break;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              b.propertyTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Metode: ${b.paymentMethod}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            currencyFormat.format(b.paymentAmount > 0 ? b.paymentAmount : b.propertyPrice),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _brown),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDetailStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _brown, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _brown),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionPlaceholder({required String message, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF6EC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _brown, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<AdminUserModel> filteredUsers) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final paginatedUsers = filteredUsers.sublist(
      startIndex,
      endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
    );

    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama, email atau nomor...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _brown),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _currentPage = 1;
                  });
                },
              ),
            ),
          ),
          const Divider(height: 1, color: _border),
          Expanded(
            child: paginatedUsers.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: paginatedUsers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _UserCard(
                      user: paginatedUsers[i],
                      onTap: () => _showBuyerDetails(paginatedUsers[i]),
                      border: _border,
                      brown: _brown,
                    ),
                  ),
          ),
          const Divider(height: 1, color: _border),
          _buildLeftPanePagination(filteredUsers.length),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(backgroundColor: _brown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Belum ada data pembeli', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback onTap;
  final Color border;
  final Color brown;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.border,
    required this.brown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFDD096),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}