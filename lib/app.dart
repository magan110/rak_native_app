import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';

/// Root application widget
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RAK App',
      debugShowCheckedModeBanner: false,

      // Theme - Force light mode
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme, // Use light theme for dark mode too
      themeMode: ThemeMode.light, // Force light mode

      // Routing with go_router
      routerConfig: AppRouter.router,
    );
  }
}
