import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';

class ModernDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isRequired;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? icon; // Alias for prefixIcon

  const ModernDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.hint,
    this.prefixIcon,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final IconData? actualIcon = icon ?? prefixIcon;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;
    final hintColor = colorScheme.onSurface.withOpacity(0.6);
    final iconColor = colorScheme.onSurface.withOpacity(0.7);
    final containerColor = colorScheme.surface;
    final borderColor = colorScheme.onSurface.withOpacity(0.12);
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
                color: textColor,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: DropdownButtonFormField<String>(
            hint: Text(
              hint ?? 'Select $label',
              style: TextStyle(
                color: hintColor,
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
            ),
            decoration: InputDecoration(
              prefixIcon: actualIcon != null
                  ? Icon(actualIcon, color: iconColor, size: 20)
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: actualIcon != null ? 8 : 16,
                vertical: 16,
              ),
            ),
            isExpanded: true,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    color: textColor,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
            dropdownColor: colorScheme.surface,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
