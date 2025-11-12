import 'package:flutter/material.dart';

class DualLogoWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final double spacing;
  final bool isCircular;

  const DualLogoWidget({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.spacing = 8.0,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoHeight = height ?? 40.0;
    final logoWidth = width ?? 40.0;

    // Ensure minimum spacing and calculate individual logo size
    final safeSpacing = spacing.clamp(4.0, logoWidth * 0.12);
    final containerPadding = isCircular ? 0.0 : 4.0;
    final availableWidth = (logoWidth - containerPadding).clamp(
      40.0,
      double.infinity,
    );
    final availableHeight = (logoHeight - containerPadding).clamp(
      20.0,
      double.infinity,
    );
    final individualLogoWidth = ((availableWidth - safeSpacing) / 2).clamp(
      15.0,
      double.infinity,
    );
    final individualLogoHeight = availableHeight;

    return Container(
      width: logoWidth,
      height: logoHeight,
      decoration: BoxDecoration(
        color: isCircular ? null : Colors.white.withValues(alpha: 0.05),
        borderRadius: isCircular ? null : BorderRadius.circular(8.0),
      ),
      padding: isCircular ? EdgeInsets.zero : const EdgeInsets.all(2.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // RAK Logo
              Flexible(
                flex: 1,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: individualLogoWidth,
                    maxHeight: individualLogoHeight,
                  ),
                  child: _buildLogoWithAspectRatio(
                    'assets/images/rak_logo.jpg',
                    individualLogoHeight,
                    individualLogoWidth,
                    Icons.business,
                    isRakLogo: true,
                  ),
                ),
              ),
              SizedBox(width: safeSpacing),
              // Birla Logo
              Flexible(
                flex: 1,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: individualLogoWidth,
                    maxHeight: individualLogoHeight,
                  ),
                  child: _buildLogoWithAspectRatio(
                    'assets/images/birla_logo.png',
                    individualLogoHeight,
                    individualLogoWidth,
                    Icons.apartment,
                    isRakLogo: false,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoWithAspectRatio(
    String assetPath,
    double height,
    double width,
    IconData fallbackIcon, {
    required bool isRakLogo,
  }) {
    // Different sizing strategies for each logo to ensure visual balance
    Widget logoImage;
    
    if (isRakLogo) {
      // RAK logo - use standard sizing
      logoImage = Image.asset(
        assetPath,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(fallbackIcon, height, width),
      );
    } else {
      // Birla logo - use height-constrained sizing for better visual matching
      logoImage = SizedBox(
        height: height,
        child: Image.asset(
          assetPath,
          fit: BoxFit.fitHeight, // Fit to height to match RAK logo visual height
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(fallbackIcon, height, width),
        ),
      );
    }

    Widget logoWidget = Container(
      constraints: BoxConstraints(
        maxHeight: height,
        maxWidth: width,
        minHeight: 20.0,
        minWidth: 20.0,
      ),
      child: ClipRRect(
        borderRadius: isCircular
            ? BorderRadius.circular(height / 2)
            : BorderRadius.circular(6.0),
        child: logoImage,
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
              ? BorderRadius.circular(height / 2)
              : BorderRadius.circular(8.0),
        ),
        child: logoWidget,
      );
    }

    return logoWidget;
  }

  Widget _buildFallbackIcon(IconData fallbackIcon, double height, double width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF2C5282).withValues(alpha: 0.1),
        borderRadius: isCircular
            ? BorderRadius.circular(height / 2)
            : BorderRadius.circular(6.0),
      ),
      child: Icon(
        fallbackIcon,
        size: (height * 0.5).clamp(16.0, 48.0),
        color: const Color(0xFF2C5282),
      ),
    );
  }
}
