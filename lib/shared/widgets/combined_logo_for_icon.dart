import 'package:flutter/material.dart';

/// Widget to create a combined logo for app icon generation
/// This creates a single widget with both logos side by side
class CombinedLogoForIcon extends StatelessWidget {
  final double size;

  const CombinedLogoForIcon({
    super.key,
    this.size = 512.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // RAK Logo
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/rak_logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5282),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'RAK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.08,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: size * 0.02),
            // Birla Logo
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/birla_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'B',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}