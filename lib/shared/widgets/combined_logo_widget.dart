import 'package:flutter/material.dart';

class CombinedLogoWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool isCircular;

  const CombinedLogoWidget({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoHeight = height ?? 40.0;
    final logoWidth = width ?? 80.0; // Default wider for combined logo

    Widget logoWidget = Container(
      constraints: BoxConstraints(
        maxHeight: logoHeight,
        maxWidth: logoWidth,
        minHeight: 20.0,
        minWidth: 40.0,
      ),
      child: ClipRRect(
        borderRadius: isCircular
            ? BorderRadius.circular(logoHeight / 2)
            : BorderRadius.circular(6.0),
        child: Image.asset(
          'assets/images/Birla_and_rak_logo.png',
          height: logoHeight,
          width: logoWidth,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: logoHeight,
              width: logoWidth,
              decoration: BoxDecoration(
                color: const Color(0xFF2C5282).withValues(alpha: 0.1),
                borderRadius: isCircular
                    ? BorderRadius.circular(logoHeight / 2)
                    : BorderRadius.circular(6.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business,
                    size: (logoHeight * 0.3).clamp(12.0, 24.0),
                    color: const Color(0xFF2C5282),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.apartment,
                    size: (logoHeight * 0.3).clamp(12.0, 24.0),
                    color: const Color(0xFF2C5282),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (showBorder) {
      logoWidget = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor ?? const Color(0xFF2C5282),
            width: borderWidth,
          ),
          borderRadius: isCircular
              ? BorderRadius.circular(logoHeight / 2)
              : BorderRadius.circular(8.0),
        ),
        child: logoWidget,
      );
    }

    return logoWidget;
  }
}