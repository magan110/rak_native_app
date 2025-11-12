import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/features/quality_control/approval_dashboard.dart';
import 'package:rak_app/features/quality_control/dashboard.dart';
import 'package:rak_app/features/retailer/screens/retailer_onboarding_screen.dart';
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
        builder: (context, state) => const ContractorRegistrationScreen(),
      ),

      // Painter Registration Screen
      GoRoute(
        path: RouteNames.painterRegistration,
        name: 'painter-registration',
        builder: (context, state) => const PainterRegistrationScreen(),
      ),

      // Painter Update Screen
      GoRoute(
        path: RouteNames.painterUpdate,
        name: 'painter-update',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final mobile = extras['mobile'] as String? ?? 
                        extras['mobileNumber'] as String? ?? '';
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
          final mobile = extras['mobile'] as String? ?? 
                        extras['mobileNumber'] as String? ?? '';
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
        builder: (context, state) => const RetailerOnboardingScreen(),
      ),

      // Admin User Edit Screen
      GoRoute(
        path: '/admin-user-edit',
        name: 'admin-user-edit',
        builder: (context, state) => const AdminUserEditScreen(),
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
