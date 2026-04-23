import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/features/quality_control/approval_dashboard.dart';
import 'package:rak_app/features/quality_control/dashboard.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/retailer_registration_screen.dart';
import 'package:rak_app/features/activity/screens/activity_entry_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/main_screens/splash_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/login_screens/login_with_password_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/login_screens/login_screen_with_otp.dart';
import 'package:rak_app/features/screens/presentation/pages/main_screens/home_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/main_screens/contractor_home_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/main_screens/painter_home_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/main_screens/notifications_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/main_screens/product_details_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/registration_type_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/contractor_registration_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/painter_registration_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/painter_update_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/contractor_update_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/registration_details_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/main_screens/camera_scanner.dart';
import 'package:rak_app/features/screens/presentation/pages/admin_screens/admin_user_edit_screen.dart';
import 'package:rak_app/features/user_management/user_list_screen.dart';
import 'package:rak_app/features/sample_distribution/sample_distribution_entry_screen.dart';
import 'package:rak_app/features/sample_execution/sample_execution_entry_screen.dart';
import 'package:rak_app/features/trade_partner_journey/presentation/screens/trade_partner_home_screen.dart';
import 'package:rak_app/features/trade_partner_journey/presentation/screens/product_catalog_screen.dart';
import 'package:rak_app/features/trade_partner_journey/presentation/screens/place_order_screen.dart';
import 'package:rak_app/features/trade_partner_journey/presentation/screens/order_history_screen.dart';
import 'package:rak_app/features/trade_partner_journey/presentation/screens/ledger_screen.dart';
import 'package:rak_app/features/trade_partner_journey/presentation/screens/schemes_screen.dart';
import 'package:rak_app/features/trade_partner_journey/presentation/screens/grievance_screen.dart';
import 'package:rak_app/features/stock_visibility/presentation/screens/stock_entry_screen.dart';
import 'package:rak_app/features/stock_visibility/presentation/screens/aging_stock_screen.dart';
import 'package:rak_app/features/market_mapping/presentation/screens/market_mapping_home_screen.dart';
import 'package:rak_app/features/market_mapping/presentation/screens/competitor_pricing_screen.dart';
import 'package:rak_app/features/market_mapping/presentation/screens/new_launches_screen.dart';
import 'package:rak_app/features/market_mapping/presentation/screens/discount_tracking_screen.dart';
import 'package:rak_app/features/market_mapping/presentation/screens/market_intelligence_screen.dart';
import 'package:rak_app/features/sales_monitoring/presentation/screens/sales_monitoring_home_screen.dart';
import 'package:rak_app/features/sales_monitoring/presentation/screens/counter_mapping_screen.dart';
import 'package:rak_app/features/product_journey/presentation/screens/product_journey_screen.dart';
import 'package:rak_app/core/models/trade_partner_models.dart';
import 'package:rak_app/features/dsr/presentation/dsr_entry_screen.dart';
import 'route_names.dart';

/// Application Router with go_router
class AppRouter {
  // Simple authentication notifier
  static final ValueNotifier<bool> _authChangeNotifier = ValueNotifier<bool>(
    false,
  );

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: _authChangeNotifier,
    routes: [
      // Splash Screen (Initial Route)
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Dashboard Screen
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      //Approval Dashboard
      GoRoute(
        path: '/approval-dashboard',
        name: 'approval-dashboard',
        builder: (context, state) => const ApprovalDashboardScreen(),
      ),

      // Registration Details Screen
      GoRoute(
        path: '/registration-details/:registrationId',
        name: 'registration-details',
        builder: (context, state) {
          final registrationId = state.pathParameters['registrationId'];
          return RegistrationDetailsScreen(registrationId: registrationId);
        },
      ),

      // Login Screen with Password
      GoRoute(
        path: RouteNames.loginWithPassword,
        name: 'login-with-password',
        builder: (context, state) => const LoginWithPasswordScreen(),
      ),

      // Login Screen with OTP
      GoRoute(
        path: RouteNames.loginWithOtp,
        name: 'login-with-otp',
        builder: (context, state) => const LoginScreenWithOtp(),
      ),

      // Registration Type Screen
      GoRoute(
        path: RouteNames.registrationType,
        name: 'registration-type',
        builder: (context, state) => const RegistrationTypeScreen(),
      ),

      // Home Screen
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Camera Scanner Screen
      GoRoute(
        path: RouteNames.cameraScanner,
        name: 'camera-scanner',
        builder: (context, state) => const CameraScannerScreen(),
      ),

      // Notifications Screen
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Product Details Screen
      GoRoute(
        path: RouteNames.productDetails,
        name: 'product-details',
        builder: (context, state) => const ProductDetailsScreen(),
      ),

      // Contractor Registration Screen
      GoRoute(
        path: RouteNames.contractorRegistration,
        name: 'contractor-registration',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final isEmployeeRegistration =
              extras['isEmployeeRegistration'] as bool? ?? false;
          return ContractorRegistrationScreen(
            isEmployeeRegistration: isEmployeeRegistration,
          );
        },
      ),

      // Painter Registration Screen
      GoRoute(
        path: RouteNames.painterRegistration,
        name: 'painter-registration',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final isEmployeeRegistration =
              extras['isEmployeeRegistration'] as bool? ?? false;
          return PainterRegistrationScreen(
            isEmployeeRegistration: isEmployeeRegistration,
          );
        },
      ),

      // Painter Update Screen
      GoRoute(
        path: RouteNames.painterUpdate,
        name: 'painter-update',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final mobile =
              extras['mobile'] as String? ??
              extras['mobileNumber'] as String? ??
              '';
          final userProfile = extras['userProfile'];
          final missingFields = extras['missingFields'] as List<String>?;
          final completionMessage = extras['completionMessage'] as String?;

          return PainterUpdateScreen(
            mobileNumber: mobile,
            userProfile: userProfile,
            missingFields: missingFields,
            completionMessage: completionMessage,
          );
        },
      ),

      // Contractor Update Screen
      GoRoute(
        path: RouteNames.contractorUpdate,
        name: 'contractor-update',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final mobile =
              extras['mobile'] as String? ??
              extras['mobileNumber'] as String? ??
              '';
          final userProfile = extras['userProfile'];
          final missingFields = extras['missingFields'] as List<String>?;
          final completionMessage = extras['completionMessage'] as String?;

          return ContractorUpdateScreen(
            mobileNumber: mobile,
            userProfile: userProfile,
            missingFields: missingFields,
            completionMessage: completionMessage,
          );
        },
      ),

      // Contractor Home Screen (mobile native)
      GoRoute(
        path: RouteNames.contractorHome,
        name: 'contractor-home',
        builder: (context, state) {
          // Enhanced to handle profile data from OTP login
          bool isNew = false;
          String? userRole;
          String? registeredName;
          String? emirates;

          if (state.extra is bool) {
            isNew = state.extra as bool;
          } else if (state.extra is Map) {
            final m = state.extra as Map;
            isNew = m['isNewRegistration'] == true || m['isNew'] == true;
            userRole = m['userRole']?.toString();

            // Try to get name from profile data first, then fallback to legacy
            final userProfile = m['userProfile'];
            if (userProfile != null) {
              registeredName = userProfile.fullName;
              emirates = userProfile.emirates;
            } else {
              registeredName = m['registeredName']?.toString();
              emirates = m['emirates']?.toString();
            }
          }

          return ContractorHomeScreen(
            isNewRegistration: isNew,
            userRole: userRole,
            registeredName: registeredName,
            emirates: emirates,
          );
        },
      ),

      // Painter Home Screen (mobile native)
      GoRoute(
        path: RouteNames.painterHome,
        name: 'painter-home',
        builder: (context, state) {
          // Enhanced to handle profile data from OTP login
          bool isNew = false;
          String? userRole;
          String? registeredName;
          String? emirates;

          if (state.extra is bool) {
            isNew = state.extra as bool;
          } else if (state.extra is Map) {
            final m = state.extra as Map;
            isNew = m['isNewRegistration'] == true || m['isNew'] == true;
            userRole = m['userRole']?.toString();

            // Try to get name from profile data first, then fallback to legacy
            final userProfile = m['userProfile'];
            if (userProfile != null) {
              registeredName = userProfile.fullName;
              emirates = userProfile.emirates;
            } else {
              registeredName = m['registeredName']?.toString();
              emirates = m['emirates']?.toString();
            }
          }

          return PainterHomeScreen(
            isNewRegistration: isNew,
            userRole: userRole,
            registeredName: registeredName,
            emirates: emirates,
          );
        },
      ),

      // Retailer Registration Screen
      GoRoute(
        path: RouteNames.retailerRegistration,
        name: 'retailer-registration',
        builder: (context, state) => const RetailerRegistrationScreen(),
      ),

      // Activity Entry Screen
      GoRoute(
        path: '/activity-entry',
        name: 'activity-entry',
        builder: (context, state) => const ActivityEntryScreen(),
      ),

      // Admin User Edit Screen
      GoRoute(
        path: '/admin-user-edit',
        name: 'admin-user-edit',
        builder: (context, state) => const AdminUserEditScreen(),
      ),

      // User List Screen (User Management)
      GoRoute(
        path: '/user-list',
        name: 'user-list',
        builder: (context, state) => const UserListScreen(),
      ),

      // Sample Distribution Entry Screen
      GoRoute(
        path: '/sample-distribution',
        name: 'sample-distribution',
        builder: (context, state) => const SampleDistributionEntryScreen(),
      ),

      // Sample Execution Entry Screen
      GoRoute(
        path: '/sample-execution',
        name: 'sample-execution',
        builder: (context, state) => const SampleExecutionEntryScreen(),
      ),

      // ============================================
      // TRADE PARTNER JOURNEY ROUTES
      // ============================================

      // Trade Partner Home Screen
      GoRoute(
        path: RouteNames.tradePartnerHome,
        name: 'trade-partner-home',
        builder: (context, state) => const TradePartnerHomeScreen(),
      ),

      // Product Catalog Screen
      GoRoute(
        path: RouteNames.products,
        name: 'products',
        builder: (context, state) => const ProductCatalogScreen(),
      ),

      // Place Order Screen
      GoRoute(
        path: RouteNames.placeOrder,
        name: 'place-order',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final cart = extras['cart'] as Map<String, CartItem>?;
          return PlaceOrderScreen(cart: cart);
        },
      ),

      // Order History Screen
      GoRoute(
        path: RouteNames.orders,
        name: 'orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),

      // Ledger Screen
      GoRoute(
        path: RouteNames.ledger,
        name: 'ledger',
        builder: (context, state) => const LedgerScreen(),
      ),

      // Schemes Screen
      GoRoute(
        path: RouteNames.schemes,
        name: 'schemes',
        builder: (context, state) => const SchemesScreen(),
      ),

      // Grievance Screen
      GoRoute(
        path: RouteNames.grievances,
        name: 'grievances',
        builder: (context, state) => const GrievanceScreen(),
      ),

      // Stock Entry Screen
      GoRoute(
        path: RouteNames.stockEntry,
        name: 'stock-entry',
        builder: (context, state) => const StockEntryScreen(),
      ),

      // Aging Stock Screen
      GoRoute(
        path: RouteNames.agingStock,
        name: 'aging-stock',
        builder: (context, state) => const AgingStockScreen(),
      ),

      // Market Mapping Home
      GoRoute(
        path: RouteNames.marketMappingHome,
        name: 'market-mapping-home',
        builder: (context, state) => const MarketMappingHomeScreen(),
      ),

      // Competitor Pricing
      GoRoute(
        path: RouteNames.competitorPricing,
        name: 'competitor-pricing',
        builder: (context, state) => const CompetitorPricingScreen(),
      ),

      // New Launches
      GoRoute(
        path: RouteNames.newLaunches,
        name: 'new-launches',
        builder: (context, state) => const NewLaunchesScreen(),
      ),

      // Discount Tracking
      GoRoute(
        path: RouteNames.discountTracking,
        name: 'discount-tracking',
        builder: (context, state) => const DiscountTrackingScreen(),
      ),

      // Market Intelligence
      GoRoute(
        path: RouteNames.marketIntelligence,
        name: 'market-intelligence',
        builder: (context, state) => const MarketIntelligenceScreen(),
      ),

      // Sales Monitoring Home
      GoRoute(
        path: RouteNames.salesMonitoringHome,
        name: 'sales-monitoring-home',
        builder: (context, state) => const SalesMonitoringHomeScreen(),
      ),

      // Counter Mapping
      GoRoute(
        path: RouteNames.counterMapping,
        name: 'counter-mapping',
        builder: (context, state) => const CounterMappingScreen(),
      ),

      // Product Journey
      GoRoute(
        path: RouteNames.productJourney,
        name: 'product-journey',
        builder: (context, state) => const ProductJourneyScreen(),
      ),

      // DSR Entry Screen
      GoRoute(
        path: '/dsr-entry',
        name: 'dsr-entry',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final loginId = extras['loginId'] as String? ?? '';
          return DsrEntryScreen(loginId: loginId);
        },
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: SizedBox.shrink(), // Blank screen for unknown routes
    ),
  );

  /// Notify auth state change
  static void notifyAuthChange() {
    _authChangeNotifier.value = !_authChangeNotifier.value;
  }

  /// Handle logout navigation
  static void logout(BuildContext context) {
    context.go(RouteNames.loginWithPassword);
  }
}
