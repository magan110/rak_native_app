import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/features/retailer/screens/retailer_onboarding_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/main_screens/splash_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/login_screens/login_with_password_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/main_screens/home_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/registration_type_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/contractor_registration_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/painter_registration_screen.dart';
import 'package:rak_app/features/screens/presentation/pages/registration_screens/retailer_registration_screen.dart';
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

      // Login Screen with Password
      GoRoute(
        path: RouteNames.loginWithPassword,
        name: 'login-with-password',
        builder: (context, state) => const LoginWithPasswordScreen(),
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

      // Retailer Registration Screen
      GoRoute(
        path: RouteNames.retailerRegistration,
        name: 'retailer-registration',
        builder: (context, state) => const RetailerOnboardingScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Path: ${state.uri.path}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.splash),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );

  /// Notify auth state change
  static void notifyAuthChange() {
    _authChangeNotifier.value = !_authChangeNotifier.value;
  }
}
