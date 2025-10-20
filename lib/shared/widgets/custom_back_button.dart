import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final bool animated;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new,
        color: color ?? Colors.black87,
        size: size ?? 20,
      ),
      onPressed: onPressed ?? () => context.pop(),
      tooltip: 'Back',
    );
  }
}
