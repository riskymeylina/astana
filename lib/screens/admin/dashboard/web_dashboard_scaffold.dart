import 'package:flutter/material.dart';
import 'views/staff_dashboard_main_view.dart';
import '../../../services/auth_service.dart';
import 'web_sidebar.dart';
import 'views/dashboard_main_view.dart';
import '../../../features/admin/properties/admin_properties_page.dart';
import '../../admin/manage_buyer_records_page.dart';
import '../../admin/manage_staff_page.dart';
import '../../surveys/marketing_survey_requests_page.dart';
import '../../consultation/manage_consultations_page.dart';
import '../../property/marketing_property_availability_page.dart';
import '../../purchases/marketing_transaction_recap_page.dart';
import '../../admin/sales_report_page.dart';
import '../../notifications/notifications_page.dart';

class WebDashboardScaffold extends StatefulWidget {
  final int initialIndex;

  const WebDashboardScaffold({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<WebDashboardScaffold> createState() => _WebDashboardScaffoldState();
}

class _WebDashboardScaffoldState extends State<WebDashboardScaffold> {
  final AuthService _authService = AuthService();
  late int _selectedIndex;
  String _userName = 'Pengguna';
  String _userRole = 'Admin';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final session = _authService.getSession();
    if (session != null) {
      setState(() {
        _userName = session['name']?.toString() ?? 'Pengguna';
        final role = session['role']?.toString().toLowerCase() ?? 'admin';
        _userRole = role == 'admin' ? 'Super Admin' : 'Staf Marketing';
      });
    }
  }

  void _onMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onLogout() async {
    await _authService.clearSession();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

Widget _buildContent() {
    // Determine view based on role
    final isStaff = _userRole.toLowerCase().contains('staf');
    if (isStaff) {
      switch (_selectedIndex) {
        case 0:
          return StaffDashboardMainView(userName: _userName, userRole: _userRole);
        case 1:
          return const MarketingSurveyRequestsPage();
        case 2:
          return const ManageConsultationsPage();
        case 3:
          return const MarketingPropertyAvailabilityPage();
        case 4:
          return const MarketingTransactionRecapPage();
        default:
          return StaffDashboardMainView(userName: _userName, userRole: _userRole);
      }
    }
    // Default admin view
    switch (_selectedIndex) {
      case 0:
        return DashboardMainView(userName: _userName, userRole: _userRole);
      case 1:
        return const AdminPropertiesPage();
      case 2:
        return const SalesReportPage();
      case 3:
        return const ManageBuyerRecordsPage();
      case 4:
        return const ManageStaffPage();
      case 5:
        return const NotificationsPage();
      default:
        return DashboardMainView(userName: _userName, userRole: _userRole);
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: Row(
        children: [
          WebSidebar(
            selectedIndex: _selectedIndex,
            onMenuTap: _onMenuTap,
            userName: _userName,
            userRole: _userRole,
            onLogout: _onLogout,
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}