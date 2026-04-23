import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Centralized SnackBar utility to replace the dozens of
/// _showErrorSnackBar / _showSuccessSnackBar methods scattered across screens.
class AppSnackBar {
  /// Show a success message (green)
  static void showSuccess(BuildContext context, String message, {IconData? icon}) {
    _show(
      context,
      message: message,
      icon: icon ?? Icons.check_circle_rounded,
      backgroundColor: AppColors.success,
    );
  }

  /// Show an error message (red)
  static void showError(BuildContext context, String message, {IconData? icon}) {
    _show(
      context,
      message: message,
      icon: icon ?? Icons.error_outline_rounded,
      backgroundColor: AppColors.error,
    );
  }

  /// Show a warning message (amber)
  static void showWarning(BuildContext context, String message, {IconData? icon}) {
    _show(
      context,
      message: message,
      icon: icon ?? Icons.warning_amber_rounded,
      backgroundColor: AppColors.warning,
    );
  }

  /// Show an info message (blue)
  static void showInfo(BuildContext context, String message, {IconData? icon}) {
    _show(
      context,
      message: message,
      icon: icon ?? Icons.info_outline_rounded,
      backgroundColor: AppColors.info,
    );
  }

  /// Show a loading snackbar with circular progress indicator
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    BuildContext context,
    String message,
  ) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Hide current snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Internal method to show a styled snackbar
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
