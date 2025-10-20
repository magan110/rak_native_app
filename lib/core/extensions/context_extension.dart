import 'package:flutter/material.dart';

/// BuildContext extensions for easier access to common properties
extension ContextExtension on BuildContext {
  /// Get theme data
  ThemeData get theme => Theme.of(this);
  
  /// Get text theme
  TextTheme get textTheme => theme.textTheme;
  
  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Get screen size
  Size get screenSize => mediaQuery.size;
  
  /// Get screen width
  double get screenWidth => screenSize.width;
  
  /// Get screen height
  double get screenHeight => screenSize.height;
  
  /// Check if keyboard is visible
  bool get isKeyboardVisible => mediaQuery.viewInsets.bottom > 0;
  
  /// Get safe area padding
  EdgeInsets get padding => mediaQuery.padding;
  
  /// Check if device is in dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }
}
