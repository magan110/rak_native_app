import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/responsive_utils.dart';

/// Responsive spacing widget that adapts to screen size
class ResponsiveSpacing extends StatelessWidget {
  final double mobile;
  final double? tablet;
  final double? desktop;

  const ResponsiveSpacing({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.25,
      desktop: desktop ?? mobile * 1.5,
    );
    return SizedBox(height: spacing);
  }
}

/// Responsive section container
class ResponsiveSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets? padding;
  final IconData? icon;
  final String? subtitle;
  final bool isOptional;

  const ResponsiveSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
    this.icon,
    this.subtitle,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          padding ??
          EdgeInsets.all(
            ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFF3B82F6), size: 24),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 18,
                                tablet: 20,
                                desktop: 22,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isOptional) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Responsive row that adapts layout based on screen size
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final bool forceColumn;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.forceColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final shouldBeColumn = forceColumn || isMobile;

    if (shouldBeColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildChildrenWithSpacing(children, spacing, isColumn: true),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildChildrenWithSpacing(children, spacing, isColumn: false),
    );
  }

  List<Widget> _buildChildrenWithSpacing(
    List<Widget> items,
    double space, {
    required bool isColumn,
  }) {
    final List<Widget> result = [];
    for (int i = 0; i < items.length; i++) {
      if (isColumn) {
        result.add(items[i]);
        if (i < items.length - 1) {
          result.add(SizedBox(height: space));
        }
      } else {
        result.add(Expanded(child: items[i]));
        if (i < items.length - 1) {
          result.add(SizedBox(width: space));
        }
      }
    }
    return result;
  }
}

/// Responsive text field that adapts to screen size
class ResponsiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isRequired;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? prefixIcon;
  final IconData? icon; // Alias for prefixIcon
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool isPhone;

  const ResponsiveTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isRequired = true,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.prefixIcon,
    this.icon,
    this.suffixIcon,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    final IconData? actualIcon = icon ?? prefixIcon;
    final TextInputType? actualKeyboardType = isPhone
        ? TextInputType.phone
        : keyboardType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              isRequired ? '$label *' : label,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          keyboardType: actualKeyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
            ),
            prefixIcon: actualIcon != null
                ? Icon(actualIcon, color: Colors.grey[600], size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: actualIcon != null ? 8 : 16,
              vertical: 16,
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Responsive date field widget
class ResponsiveDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isRequired;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const ResponsiveDateField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isRequired = false,
    this.icon,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveTextField(
      controller: controller,
      label: label,
      hint: hint,
      isRequired: isRequired,
      icon: icon ?? Icons.calendar_today_outlined,
      readOnly: true,
      onTap:
          onTap ??
          () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              controller.text = '${date.day}/${date.month}/${date.year}';
            }
          },
      validator: validator,
    );
  }
}

/// Responsive info card widget
class ResponsiveInfoCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? subtitle; // Alias for description
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const ResponsiveInfoCard({
    super.key,
    required this.title,
    this.description,
    this.subtitle,
    this.icon = Icons.info_outline,
    this.color,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? const Color(0xFF3B82F6);
    final actualDescription = subtitle ?? description ?? '';
    final bgColor = backgroundColor ?? cardColor.withOpacity(0.05);
    final actualIconColor = iconColor ?? cardColor;
    final actualTextColor = textColor ?? Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: actualIconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.w600,
                    color: cardColor.withOpacity(0.9),
                  ),
                ),
                if (actualDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    actualDescription,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                      color: actualTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
