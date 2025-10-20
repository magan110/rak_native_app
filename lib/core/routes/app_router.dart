import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth screens
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/login_screens/login_screen_with_otp.dart';
import '../../features/auth/presentation/pages/login_screens/login_with_password_screen.dart';

// Registration screens
import '../../features/auth/presentation/pages/registration_screens/registration_type_screen.dart';
import '../../features/auth/presentation/pages/registration_screens/contractor_registration_screen.dart';
import '../../features/auth/presentation/pages/registration_screens/painter_registration_screen.dart';
import '../../features/auth/presentation/pages/registration_screens/registration_details_screen.dart';
import '../../features/auth/presentation/pages/registration_screens/success_screen.dart';

// Home screen
import '../../features/auth/presentation/pages/main_screens/home_screen.dart';

// Retail screens
import '../../features/retail/presentation/pages/retailer_onboarding_app.dart';

// Product screens
import '../../features/products/presentation/pages/new_product_entry.dart';
import '../../features/products/presentation/pages/sample_distribut_entry.dart';
import '../../features/products/presentation/pages/sampling_drive_form_page.dart';
import '../../features/products/presentation/pages/incentive_scheme_form_page.dart';

// Quality Control screens
import '../../features/quality_control/presentation/pages/approval_dashboard_screen.dart';
import '../../features/quality_control/presentation/pages/dashboard_screen.dart';

// Activity screens
import '../../features/activity/presentation/pages/activity_entry_screen.dart';

// Support screens
import '../../features/support/presentation/pages/contact_us_screen.dart';

// Shared screens
import '../../shared/presentation/pages/file_manager_screen.dart';
import '../../shared/presentation/pages/camera_scanner_screen.dart';
import '../../shared/presentation/pages/qr_input_screen.dart';

/// Application Router with go_router
class AppRouter {
  // Simple authentication notifier (can be replaced with proper implementation)
  static final ValueNotifier<bool> _authChangeNotifier = ValueNotifier<bool>(
    false,
  );

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _authChangeNotifier,
    redirect: _handleRedirect,
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login-otp',
        name: 'login-otp',
        builder: (context, state) => const LoginScreenWithOtp(),
      ),
      GoRoute(
        path: '/login-password',
        name: 'login-password',
        builder: (context, state) => const LoginWithPasswordScreen(),
      ),

      // Registration Routes
      GoRoute(
        path: '/registration-type',
        name: 'registration-type',
        builder: (context, state) => const RegistrationTypeScreen(),
      ),
      GoRoute(
        path: '/registration/contractor',
        name: 'contractor-registration',
        builder: (context, state) => const ContractorRegistrationScreen(),
      ),
      GoRoute(
        path: '/registration/painter',
        name: 'painter-registration',
        builder: (context, state) => const PainterRegistrationScreen(),
      ),
      GoRoute(
        path: '/registration/details/:id',
        name: 'registration-details',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return RegistrationDetailsScreen(registrationId: id ?? '');
        },
      ),
      GoRoute(
        path: '/registration/success',
        name: 'registration-success',
        builder: (context, state) => const SuccessScreen(),
      ),

      // Home Route
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Retail Routes
      GoRoute(
        path: '/retail-onboarding',
        name: 'retail-onboarding',
        builder: (context, state) => const RetailerOnboardingApp(),
      ),

      // Product Routes
      GoRoute(
        path: '/products/new-entry',
        name: 'new-product-entry',
        builder: (context, state) => const NewProductEntry(),
      ),
      GoRoute(
        path: '/products/sample-distribution',
        name: 'sample-distribution',
        builder: (context, state) => const SampleDistributEntry(),
      ),
      GoRoute(
        path: '/products/sampling-drive',
        name: 'sampling-drive',
        builder: (context, state) => const SamplingDriveFormPage(),
      ),
      GoRoute(
        path: '/products/incentive-scheme',
        name: 'incentive-scheme',
        builder: (context, state) => const IncentiveSchemeFormPage(),
      ),

      // Quality Control Routes
      GoRoute(
        path: '/qc-approval',
        name: 'qc-approval',
        builder: (context, state) => const ApprovalDashboardScreen(),
      ),
      GoRoute(
        path: '/qc-dashboard',
        name: 'qc-dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Activity Routes
      GoRoute(
        path: '/activity-entry',
        name: 'activity-entry',
        builder: (context, state) => const ActivityEntryScreen(),
      ),

      // Support Routes
      GoRoute(
        path: '/contact-us',
        name: 'contact-us',
        builder: (context, state) => const ContactUsScreen(),
      ),

      // Shared/Common Routes
      GoRoute(
        path: '/file-manager',
        name: 'file-manager',
        builder: (context, state) => const FileManagerScreen(),
      ),
      GoRoute(
        path: '/camera-scanner',
        name: 'camera-scanner',
        builder: (context, state) => const CameraScannerScreen(),
      ),
      GoRoute(
        path: '/qr-input',
        name: 'qr-input',
        builder: (context, state) => const QRInputScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.path}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );

  /// Authentication redirect handler
  /// TODO: Implement proper authentication check with AuthService
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    // For now, allow all routes (can be enhanced with AuthService)
    // Uncomment and implement when auth integration is ready:
    /*
    final isAuthenticated = _checkAuthentication();
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/registration') ||
        state.matchedLocation == '/splash';

    // If not authenticated and trying to access protected route
    if (!isAuthenticated && !isAuthRoute) {
      return '/splash';
    }

    // If authenticated and trying to access auth route
    if (isAuthenticated && isAuthRoute && state.matchedLocation != '/splash') {
      return '/home';
    }
    */

    // No redirect needed (allow all routes)
    return null;
  }

  /// Check if user is authenticated (placeholder implementation)
  /// TODO: Integrate with AuthService for proper auth check
  static bool _checkAuthentication() {
    // This is a placeholder - implement proper auth check
    // Could check StorageService for saved tokens/user data
    return false;
  }

  /// Notify auth state change
  static void notifyAuthChange() {
    _authChangeNotifier.value = !_authChangeNotifier.value;
  }
}
