import 'package:flutter/material.dart';

import '../../../services/admin_user_service.dart';
import '../../../models/admin_models.dart';
import '../../../widgets/braga_page_header.dart';

class ManageStaffPage extends StatefulWidget {
  const ManageStaffPage({super.key});

  @override
  State<ManageStaffPage> createState() => _ManageStaffPageState();
}

class _ManageStaffPageState extends State<ManageStaffPage> {
  final AdminUserService _service = AdminUserService();

  List<AdminUserModel> _users = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Semua Status';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  static const _border = Color(0xFFE7CCAE);
  static const _brown = Color(0xFF7A4F2D);

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.getUsers(role: 'staf');
      if (res.statusCode == 200) {
        setState(() {
          _users = _service.parseUsers(res.body);
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

  String _getStaffSubtitle(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('rina')) return 'Marketing Property';
    if (lower.contains('andi')) return 'Sales Property';
    if (lower.contains('dewi')) return 'Customer Support';
    if (lower.contains('budi')) return 'Sales Property';
    return '';
  }

  String _getStaffRoleLabel(String email, String dbRole) {
    final lower = email.toLowerCase();
    if (dbRole.toLowerCase() == 'admin') return 'Admin';
    if (lower.contains('rina')) return 'Marketing';
    if (lower.contains('andi') || lower.contains('budi')) return 'Sales';
    if (lower.contains('dewi')) return 'Support';
    return 'Staff';
  }

  Color _getRoleBgColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFF3E8FF);
      case 'marketing':
      case 'sales':
        return const Color(0xFFE0F2FE);
      case 'support':
        return const Color(0xFFFFEDD5);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getRoleTextColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF6B21A8);
      case 'marketing':
      case 'sales':
        return const Color(0xFF0369A1);
      case 'support':
        return const Color(0xFFC2410C);
      default:
        return const Color(0xFF374151);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      return '$day $month $year';
    } catch (_) {
      return '-';
    }
  }

  Future<void> _deleteStaff(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Akun Staf',
          style: TextStyle(color: _brown, fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin menghapus akun staf ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      final res = await _service.deleteUser(id);
      final msg = _service.parseMessage(res.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.statusCode == 200 ? 'Akun staf berhasil dihapus' : msg,
          ),
          backgroundColor: res.statusCode == 200 ? _brown : Colors.red,
        ),
      );
      _loadStaff();
    }
  }

  void _showAddStaffDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Tambah Akun Staf',
          style: TextStyle(color: _brown, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
                ),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Email wajib diisi';
                    if (!v!.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Nomor telepon wajib diisi'
                      : null,
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _brown),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                final res = await _service.createStaff(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  password: passwordController.text,
                );
                final msg = _service.parseMessage(res.body);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.statusCode == 201
                          ? 'Akun staf berhasil ditambahkan'
                          : msg,
                    ),
                    backgroundColor: res.statusCode == 201
                        ? _brown
                        : Colors.red,
                  ),
                );
                _loadStaff();
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showEditStaffDialog(AdminUserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone ?? '');
    bool isActive = user.isActive;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFFFF8F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Ubah Data Staf',
            style: TextStyle(color: _brown, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return 'Email wajib diisi';
                      if (!v!.contains('@')) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Nomor telepon wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status Akun Aktif',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _brown,
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: _brown,
                        onChanged: (val) {
                          setDialogState(() {
                            isActive = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _brown),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  setState(() => _loading = true);
                  final res = await _service.updateStaff(
                    id: user.id,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    isActive: isActive,
                  );
                  final msg = _service.parseMessage(res.body);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        res.statusCode == 200
                            ? 'Data staf berhasil diubah'
                            : msg,
                      ),
                      backgroundColor: res.statusCode == 200
                          ? _brown
                          : Colors.red,
                    ),
                  );
                  _loadStaff();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredUsers = _users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.phone != null && user.phone!.toLowerCase().contains(query));

      if (_selectedStatus == 'Aktif') {
        return matchesSearch && user.isActive;
      } else if (_selectedStatus == 'Nonaktif') {
        return matchesSearch && !user.isActive;
      }
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Column(
        children: [
          BragaPageHeader(
            title: 'Manajemen Staf',
            subtitle: 'Kelola data seluruh staf perusahaan.',
            decorativeIcon: Icons.badge_rounded,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadStaff,
                tooltip: 'Muat ulang',
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildError()
                : Column(
                    children: [Expanded(child: _buildMainPanel(filteredUsers))],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<AdminUserModel> allUsers) {
    final total = allUsers.length;
    final active = allUsers.where((u) => u.isActive).length;
    final inactive = allUsers.where((u) => !u.isActive).length;
    final adminCount = allUsers
        .where(
          (u) =>
              u.role.toLowerCase() == 'admin' ||
              _getStaffRoleLabel(u.email, u.role) == 'Admin',
        )
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Staf',
                        '$total',
                        'Seluruh staf terdaftar',
                        Icons.people_rounded,
                        const Color(0xFF7A4F2D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Staf Aktif',
                        '$active',
                        'Sedang aktif bekerja',
                        Icons.check_circle_outline_rounded,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Staf Nonaktif',
                        '$inactive',
                        'Tidak aktif sementara',
                        Icons.pause_circle_outline_rounded,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Staf Admin',
                        '$adminCount',
                        'Akses penuh sistem',
                        Icons.admin_panel_settings_rounded,
                        Colors.deepPurple,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Staf',
                            '$total',
                            'Seluruh staf terdaftar',
                            Icons.people_rounded,
                            const Color(0xFF7A4F2D),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Staf Aktif',
                            '$active',
                            'Sedang aktif bekerja',
                            Icons.check_circle_outline_rounded,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Staf Nonaktif',
                            '$inactive',
                            'Tidak aktif sementara',
                            Icons.pause_circle_outline_rounded,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Staf Admin',
                            '$adminCount',
                            'Akses penuh sistem',
                            Icons.admin_panel_settings_rounded,
                            Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _brown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPanel(List<AdminUserModel> filteredUsers) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0DED0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F3212).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E3),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.groups_2_rounded,
                    color: _brown,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar Staf',
                        style: TextStyle(
                          color: Color(0xFF35170A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Kelola akun dan akses staf perusahaan',
                        style: TextStyle(
                          color: Color(0xFF9A887D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F3EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredUsers.length} staf',
                    style: const TextStyle(
                      color: _brown,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1E7DE)),
          Expanded(
            child: filteredUsers.isEmpty
                ? _buildEmpty()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 900) {
                        return _buildDesktopTable(filteredUsers);
                      } else {
                        return _buildMobileList(filteredUsers);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final searchField = SizedBox(
            width: isNarrow ? double.infinity : 350,
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama staf, email, atau nomor...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
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
          );

          final statusDropdown = Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                items: ['Semua Status', 'Aktif', 'Nonaktif'].map((s) {
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedStatus = val;
                      _currentPage = 1;
                    });
                  }
                },
              ),
            ),
          );

          final addButton = SizedBox(
            height: 40,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _brown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _showAddStaffDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Tambah Staf',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: statusDropdown),
                    const SizedBox(width: 10),
                    addButton,
                  ],
                ),
              ],
            );
          } else {
            return Row(
              children: [
                searchField,
                const Spacer(),
                statusDropdown,
                const SizedBox(width: 12),
                addButton,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildDesktopTable(List<AdminUserModel> filteredUsers) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final paginatedUsers = filteredUsers.sublist(
      startIndex,
      endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
    );

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.8),
          1: FlexColumnWidth(2.7),
          2: FlexColumnWidth(1.3),
          3: FlexColumnWidth(1.3),
          4: FlexColumnWidth(1.6),
          5: FixedColumnWidth(72),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFFFF7EF)),
            children: [
              _buildTableHeader('Staf'),
              _buildTableHeader('Kontak'),
              _buildTableHeader('Status'),
              _buildTableHeader('Role'),
              _buildTableHeader('Tanggal Bergabung'),
              _buildTableHeader('Aksi', align: Alignment.center),
            ],
          ),
          ...paginatedUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final sub = _getStaffSubtitle(user.email);
            final roleLabel = _getStaffRoleLabel(user.email, user.role);
            return TableRow(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : const Color(0xFFFFFCF8),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFF0E8E1)),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFFF0DD),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.role.toLowerCase() == 'admin') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F4EA),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF137333),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (sub.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                sub,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.phone!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusChip(isActive: user.isActive),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleBgColor(roleLabel),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getRoleTextColor(roleLabel),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Text(
                    _formatDate(user.createdAt),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditStaffDialog(user);
                    } else if (val == 'delete') {
                      _deleteStaff(user.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Text('Ubah Data'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hapus Akun',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(
    String text, {
    Alignment align = Alignment.centerLeft,
  }) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF8A4B2A),
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildMobileList(List<AdminUserModel> filteredUsers) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final paginatedUsers = filteredUsers.sublist(
      startIndex,
      endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
    );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: paginatedUsers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final user = paginatedUsers[i];
        final sub = _getStaffSubtitle(user.email);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFF0DD),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(isActive: user.isActive),
                      ],
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (user.phone != null && user.phone!.isNotEmpty)
                      Text(
                        user.phone!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditStaffDialog(user);
                  } else if (val == 'delete') {
                    _deleteStaff(user.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Ubah Data'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('Hapus Akun', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationBar(int totalCount) {
    final totalPages = totalCount == 0
        ? 1
        : (totalCount / _itemsPerPage).ceil();
    final startIdx = totalCount == 0
        ? 0
        : (_currentPage - 1) * _itemsPerPage + 1;
    final endIdx = (_currentPage * _itemsPerPage) > totalCount
        ? totalCount
        : (_currentPage * _itemsPerPage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final perPageDropdown = Row(
            mainAxisSize: MainAxisSize.min,
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
                    items: [5, 10, 20, 50].map((count) {
                      return DropdownMenuItem<int>(
                        value: count,
                        child: Text(
                          '$count per halaman',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
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
            ],
          );

          final statsText = Text(
            'Menampilkan $startIdx - $endIdx dari $totalCount data',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          );

          final navButtons = Row(
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
              const SizedBox(width: 6),
              ...List.generate(totalPages, (index) {
                final pageNum = index + 1;
                final isSelected = pageNum == _currentPage;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPage = pageNum;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected ? _brown : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected ? null : Border.all(color: _border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$pageNum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
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
          );

          if (isNarrow) {
            return Column(
              spacing: 8,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [perPageDropdown, statsText],
                ),
                Center(child: navButtons),
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [perPageDropdown, statsText, navButtons],
            );
          }
        },
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? _border : _border.withOpacity(0.4),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black87 : Colors.grey[300],
        ),
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
              onPressed: _loadStaff,
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
          Icon(Icons.group_off_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Belum ada data staf', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE6F4EA) : const Color(0xFFFFF0E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? const Color(0xFF137333)
                  : const Color(0xFFC2410C),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Aktif' : 'Nonaktif',
            style: TextStyle(
              fontSize: 11,
              color: isActive
                  ? const Color(0xFF137333)
                  : const Color(0xFFC2410C),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
