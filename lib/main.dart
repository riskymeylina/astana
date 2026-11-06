import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/purchase_order_model.dart';
import 'models/admin_models.dart';

import 'services/app_config.dart';
import 'services/auth_service.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/verify_code_screen.dart';
import 'screens/auth/reset_password_screen.dart';

import 'screens/home/home_page.dart';
import 'screens/home/promo_properti_page.dart';
import 'screens/explore/jelajah_page.dart';

import 'screens/consultation/consultation_page.dart';
import 'screens/consultation/consultation_detail_page.dart';
import 'screens/consultation/buyer_consultation_room_page.dart';
import 'screens/consultation/buyer_consultation_requests_page.dart';
import 'screens/consultation/manage_consultations_page.dart';

import 'screens/notifications/notifications_page.dart';

import 'screens/property/property_detail_page.dart';
import 'screens/property/property_preferences_page.dart';
import 'screens/property/property_search_page.dart';
import 'screens/property/marketing_property_availability_page.dart';

import 'features/buyer/profile/buyer_profile_page.dart';
import 'features/staff/profile/staff_profile_page.dart';
import 'features/admin/profile/admin_profile_page.dart';
import 'features/admin/properties/admin_properties_page.dart';

import 'screens/admin/manage_buyers_page.dart';
import 'screens/admin/manage_staff_page.dart';
import 'screens/admin/global_report_page.dart';
import 'screens/admin/sales_report_page.dart';
import 'screens/admin/manage_bookings_page.dart';
import 'screens/admin/invoice_management_page.dart';
import 'screens/admin/add_property_page.dart';

import 'features/admin/reports/availability_report_page.dart';
import 'features/admin/transactions/transactions_page.dart';
import 'screens/admin/dashboard/web_dashboard_scaffold.dart';

import 'features/buyer/profile/buyer_administration_page.dart';

import 'screens/surveys/buyer_survey_requests_page.dart';
import 'screens/surveys/marketing_survey_requests_page.dart';
import 'screens/surveys/survey_form_page.dart';
import 'screens/surveys/survey_detail_page.dart';
import 'screens/surveys/new_survey_selection_page.dart';

import 'screens/purchases/purchase_form_page.dart';
import 'screens/purchases/purchase_detail_page.dart';
import 'screens/purchases/purchase_status_page.dart';
import 'screens/purchases/upload_payment_page.dart';
import 'screens/purchases/manage_purchases_page.dart';
import 'screens/purchases/marketing_orders_page.dart';
import 'screens/purchases/marketing_transaction_recap_page.dart';

const Set<String> _publicRoutes = {
  '/splash',
  '/onboarding',
  '/login',
  '/register',
  '/forgot',
  '/verify',
  '/reset-password',
  '/promo-properti',
};

const Set<String> _verifiedOnlyRoutes = {
  '/property-preferences',
  '/buyer-administration',
  '/consultation',
  '/consultation-form',
  '/consultation-detail',
  '/buyer-consultation-requests',
  '/manage-consultations',
  '/staff/konsultasi',
  '/buyer-survey-requests',
  '/marketing-survey-requests',
  '/survey/new',
  '/survey-form',
  '/survey-detail',
  '/notifications',
  '/purchase-form',
  '/purchase-detail',
  '/purchase-status',
  '/upload-payment',
  '/manage-purchases',
  '/marketing-orders',
  '/marketing-property-availability',
  '/marketing-transaction-recap',
  '/admin/properties',
  '/admin/buyers',
  '/admin/staff',
  '/admin/bookings',
  '/admin/invoices',
  '/admin/add-property',
  '/admin/reports/global',
  '/admin/reports/sales',
  '/admin/reports/availability',
  '/admin/transactions',
};

Widget _errorPage(String message) {
  return Scaffold(
    body: Center(
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Route<dynamic> _buildGuardedRoute({
  required RouteSettings settings,
  required WidgetBuilder builder,
}) {
  final routeName = settings.name ?? '';
  if (_publicRoutes.contains(routeName)) {
    return MaterialPageRoute(
      settings: settings,
      builder: builder,
    );
  }

  return MaterialPageRoute(
    settings: settings,
    builder: (context) => GuardedRouteWidget(
      settings: settings,
      builder: builder,
    ),
  );
}

class GuardedRouteWidget extends StatefulWidget {
  final RouteSettings settings;
  final WidgetBuilder builder;

  const GuardedRouteWidget({
    super.key,
    required this.settings,
    required this.builder,
  });

  @override
  State<GuardedRouteWidget> createState() => _GuardedRouteWidgetState();
}

class _GuardedRouteWidgetState extends State<GuardedRouteWidget> {
  late final Future<Map<String, dynamic>?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future so that rebuilds of this widget do not re-run restoreSession()
    _sessionFuture = AuthService().restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final routeName = widget.settings.name ?? '';
        final session = snapshot.data;

        final hasSession =
            session != null &&
            (session['token'] ?? '').toString().isNotEmpty;

        final isVerified =
            (session?['sessionState'] ?? '').toString() ==
            SessionState.verified;

        // 1. Jika rute termasuk rute publik, langsung izinkan masuk
        if (_publicRoutes.contains(routeName)) {
          return widget.builder(context);
        }

        // 2. Jika sesi login tidak ditemukan, arahkan ke LoginScreen
        if (!hasSession) {
          return const LoginScreen();
        }

        // 3. Jika rute butuh verifikasi server dan status belum verified
        if (_verifiedOnlyRoutes.contains(routeName) && !isVerified) {
          return const _VerificationRequiredScreen();
        }

        // =====================================================================
        // LOGIKA FILTER AKSES BERBASIS PERAN (ROLE-BASED ACCESS CONTROL)
        // =====================================================================
        final role = (session['role'] ?? '').toString().toLowerCase();

        // Rute khusus Pembeli (Transaksi & Pengajuan Pembeli)
        const buyerOnlyRoutes = {
          '/property-preferences',
          '/buyer-administration',
          '/buyer-survey-requests',
          '/buyer-consultation-requests',
          '/survey-form',
          '/purchase-form',
          '/upload-payment',
          '/manage-purchases',
        };

        if (buyerOnlyRoutes.contains(routeName) && role != 'pembeli') {
          return _errorPage('Akses Fitur Transaksi Pembeli Ditolak');
        }

        // Proteksi Fleksibel: Rute /marketing- yang juga dapat diakses Staf
        const staffAllowedMarketingRoutes = {
          '/marketing-survey-requests',
          '/marketing-transaction-recap',
          '/marketing-property-availability',
          '/staff/ketersediaan-properti',
        };

        if (staffAllowedMarketingRoutes.contains(routeName)) {
          if (role == 'marketing' || role == 'staf' || role == 'staff' || role == 'admin') {
            return widget.builder(context);
          }
          return _errorPage('Anda tidak memiliki akses ke halaman ini');
        }

        // Aturan Proteksi Rute Global Berdasarkan Prefix URL rute
        final isAdminRoute = routeName.startsWith('/admin/');
        final isStaffRoute = routeName.startsWith('/staff/');
        final isMarketingRoute = routeName.startsWith('/marketing-');

        if (isAdminRoute && role != 'admin') {
          return _errorPage('Akses Admin Ditolak');
        }

        if (isStaffRoute && role != 'staff' && role != 'staf' && role != 'admin') {
          return _errorPage('Akses Staf Ditolak');
        }

        if (isMarketingRoute && role != 'marketing' && role != 'admin') {
          return _errorPage('Akses Fitur Marketing Ditolak');
        }

        // Jika lolos semua validasi sesi dan role
        return widget.builder(context);
      },
    );
  }
}

class _VerificationRequiredScreen extends StatelessWidget {
  const _VerificationRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Perlu tersambung ke server untuk memverifikasi sesi Anda sebelum membuka fitur ini.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID');
  await AppConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Penjualan Properti',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFDD096),
        ),
        fontFamily: 'TomatoGrotesk',
        textTheme: Typography.blackMountainView.apply(
          fontFamily: 'TomatoGrotesk',
        ),
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        /// PROPERTY DETAIL
        if (settings.name == '/property-detail') {
          final propertyId = settings.arguments as int?;

          if (propertyId == null) {
            return MaterialPageRoute(
              builder: (_) => _errorPage(
                'ID properti tidak ditemukan',
              ),
            );
          }

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => PropertyDetailPage(
              propertyId: propertyId,
            ),
          );
        }

        /// PROPERTY SEARCH
        if (settings.name == '/property-search') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => PropertySearchPage(
              initialQuery: args['query'] as String?,
              brand: args['brand'] as String?,
              minPrice: args['minPrice'] as int?,
              maxPrice: args['maxPrice'] as int?,
              status: args['status'] as String?,
              sortBy: args['sortBy'] as String?,
              title: args['title'] as String? ?? 'Cari Properti',
            ),
          );
        }

        /// CONSULTATION
        if (settings.name == '/consultation') {
          final args = settings.arguments as Map<String, dynamic>?;

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) {
              final role = (AuthService().getSession()?['role'] ?? '')
                  .toString()
                  .toLowerCase();

              final propertyId = args?['propertyId'] as int?;
              final propertyTitle = args?['propertyTitle'] as String?;

              if (propertyId != null || propertyTitle != null) {
                if (role != UserRoles.pembeli) {
                  return _errorPage('Akses Konsultasi Properti Hanya untuk Pembeli');
                }
                return ConsultationPage(
                  propertyId: propertyId,
                  propertyTitle: propertyTitle,
                );
              }

              if (role == UserRoles.staf || role == UserRoles.admin) {
                return const ManageConsultationsPage();
              }

              return const BuyerConsultationRoomPage();
            },
          );
        }

        /// CONSULTATION FORM
        if (settings.name == '/consultation-form') {
          final args = settings.arguments as Map<String, dynamic>?;

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => ConsultationPage(
              propertyId: args?['propertyId'] as int?,
              propertyTitle: args?['propertyTitle'] as String?,
            ),
          );
        }

        /// CONSULTATION DETAIL
        if (settings.name == '/consultation-detail') {
          final consultationId = settings.arguments as int?;

          if (consultationId == null) {
            return MaterialPageRoute(
              builder: (_) => _errorPage(
                'Data konsultasi tidak ditemukan',
              ),
            );
          }

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => ConsultationDetailPage(
              consultationId: consultationId,
            ),
          );
        }

        /// SURVEY NEW
        if (settings.name == '/survey/new') {
          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => const NewSurveySelectionPage(),
          );
        }

        /// SURVEY FORM
        if (settings.name == '/survey-form') {
          final args = settings.arguments as Map<String, dynamic>?;
          final propertyId = args?['propertyId'];
          final propertyTitle = args?['propertyTitle'];

          if (propertyId is! int || propertyTitle is! String) {
            return MaterialPageRoute(
              builder: (_) => _errorPage(
                'Data properti tidak ditemukan',
              ),
            );
          }

          final initialSurveyId = args?['surveyId'] as int?;
          final initialRequestedDate = args?['requestedDate'] as String?;
          final initialRequestedTime = args?['requestedTime'] as String?;
          final initialNotes = args?['notes'] as String?;

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => SurveyFormPage(
              propertyId: propertyId,
              propertyTitle: propertyTitle,
              initialSurveyId: initialSurveyId,
              initialRequestedDate: initialRequestedDate,
              initialRequestedTime: initialRequestedTime,
              initialNotes: initialNotes,
            ),
          );
        }

        /// SURVEY DETAIL
        if (settings.name == '/survey-detail') {
          final args = settings.arguments as Map<String, dynamic>?;

          if (args == null) {
            return MaterialPageRoute(
              builder: (_) => _errorPage(
                'Data survei tidak ditemukan',
              ),
            );
          }

          final surveyId = args['surveyId'];
          final propertyId = args['propertyId'];
          final propertyTitle = args['propertyTitle'];

          if (surveyId is! int || propertyId is! int || propertyTitle is! String) {
            return MaterialPageRoute(
              builder: (_) => _errorPage(
                'Parameter survei tidak valid',
              ),
            );
          }

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => SurveyDetailPage(
              surveyId: surveyId,
              propertyId: propertyId,
              propertyTitle: propertyTitle,
            ),
          );
        }

        /// PURCHASE FORM
        if (settings.name == '/purchase-form') {
          final args = settings.arguments as Map<String, dynamic>?;

          if (args == null) {
            return MaterialPageRoute(
              builder: (_) => _errorPage(
                'Data properti tidak ditemukan',
              ),
            );
          }

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => PurchaseFormPage(
              propertyId: args['propertyId'] as int,
              propertyTitle: args['propertyTitle'] as String,
              propertyPrice: args['propertyPrice'] as int,
              propertyImageUrl: args['propertyImageUrl'] as String?,
            ),
          );
        }

        /// UPLOAD PAYMENT
        if (settings.name == '/upload-payment') {
          final order = settings.arguments as PurchaseOrderModel?;

          if (order == null) {
            return MaterialPageRoute(
              builder: (_) => _errorPage(
                'Data pemesanan tidak ditemukan',
              ),
            );
          }

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => UploadPaymentPage(
              order: order,
            ),
          );
        }

        /// PURCHASE DETAIL
        if (settings.name == '/purchase-detail') {
          final purchaseId = settings.arguments as int?;

          if (purchaseId == null) {
            return MaterialPageRoute(
              builder: (_) => _errorPage(
                'Data pemesanan tidak ditemukan',
              ),
            );
          }

          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => PurchaseDetailPage(
              purchaseId: purchaseId,
            ),
          );
        }

        /// ADMIN ADD / EDIT PROPERTY
        if (settings.name == '/admin/add-property') {
          final arg = settings.arguments;
          return _buildGuardedRoute(
            settings: settings,
            builder: (_) => AddPropertyPage(
              property: arg is AdminPropertyModel ? arg : null,
            ),
          );
        }

        /// STATIC ROUTES
        final builders = <String, WidgetBuilder>{
          '/splash': (_) => const SplashScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/forgot': (_) => const ForgotPasswordScreen(),
          '/verify': (_) => const VerifyCodeScreen(),
          '/reset-password': (_) => const ResetPasswordScreen(),

          '/home': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return HomePage(
              initialIndex: args?['selectedIndex'] as int? ?? 0,
            );
          },

          '/dashboard': (_) => const WebDashboardScaffold(),
          '/promo-properti': (_) => const PromoPropertiPage(),
          '/explore': (_) => const JelajahPage(),
          '/notifications': (_) => const NotificationsPage(),

          '/profile': (_) {
            final role = (AuthService().getSession()?['role'] ?? '')
                .toString()
                .toLowerCase();

            if (role == UserRoles.admin) {
              return const AdminProfilePage();
            }
            if (role == UserRoles.staf) {
              return const StaffProfilePage();
            }
            return const BuyerProfilePage();
          },

          '/property-preferences': (_) => const PropertyPreferencesPage(),
          '/buyer-administration': (_) => const BuyerAdministrationPage(),
          '/buyer-survey-requests': (_) => const BuyerSurveyRequestsPage(),
          '/marketing-survey-requests': (_) => const MarketingSurveyRequestsPage(),
          '/buyer-consultation-requests': (_) => const BuyerConsultationRequestsPage(),
          '/manage-consultations': (_) => const ManageConsultationsPage(),
          '/staff/konsultasi': (_) => const ManageConsultationsPage(),
          '/purchase-status': (_) => const PurchaseStatusPage(),
          '/manage-purchases': (_) => const ManagePurchasesPage(),
          '/marketing-orders': (_) => const MarketingOrdersPage(),
          '/marketing-property-availability': (_) => const MarketingPropertyAvailabilityPage(),
          '/staff/ketersediaan-properti': (_) => const MarketingPropertyAvailabilityPage(),
          '/marketing-transaction-recap': (_) => const MarketingTransactionRecapPage(),

          // PERBAIKAN ROUTE: 'const' sekarang valid kembali karena class target sukses ter-import
          '/admin/properties': (_) => const AdminPropertiesPage(),
          '/admin/buyers': (_) => const ManageBuyersPage(),
          '/admin/staff': (_) => const ManageStaffPage(),
          '/admin/bookings': (_) => const ManageBookingsPage(),
          '/admin/invoices': (_) => InvoiceManagementPage(),
          '/admin/add-property': (_) => const AddPropertyPage(),
          '/admin/reports/global': (_) => const GlobalReportPage(),
          '/admin/reports/sales': (_) => const SalesReportPage(),
          '/admin/reports/availability': (_) => const AvailabilityReportPage(),
              '/admin/transactions': (_) => const TransactionsPage(),
        };

        final builder = builders[settings.name];

        if (builder == null) {
          return MaterialPageRoute(
            builder: (_) => _errorPage(
              'Halaman tidak ditemukan',
            ),
          );
        }

        return _buildGuardedRoute(
          settings: settings,
          builder: builder,
        );
      },
    );
  }
}