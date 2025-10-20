import 'package:flutter/material.dart';

/// A custom back button widget with optional animation
class CustomBackButton extends StatefulWidget {
  final bool animated;
  final double size;
  final Color? color;
  final VoidCallback? onPressed;

  const CustomBackButton({
    super.key,
    this.animated = true,
    this.size = 40,
    this.color,
    this.onPressed,
  });

  @override
  State<CustomBackButton> createState() => _CustomBackButtonState();
}

class _CustomBackButtonState extends State<CustomBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.9,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? Theme.of(context).primaryColor;

    Widget backButton = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.animated) _controller.forward();
        },
        onTapUp: (_) {
          if (widget.animated) _controller.reverse();
          _handleTap();
        },
        onTapCancel: () {
          if (widget.animated) _controller.reverse();
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isHovered
                ? buttonColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.size / 4),
            border: Border.all(
              color: _isHovered
                  ? buttonColor.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: buttonColor,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );

    if (widget.animated) {
      return ScaleTransition(scale: _scaleAnimation, child: backButton);
    }

    return backButton;
  }
}
