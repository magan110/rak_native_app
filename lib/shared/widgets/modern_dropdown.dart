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
    // Force light theme colors
    const textColor = Colors.black87;
    final hintColor = Colors.grey.shade600;
    final iconColor = Colors.grey.shade700;
    const containerColor = Colors.white;
    final borderColor = Colors.grey.shade300;
    const dropdownColor = Colors.white;
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
            value: value,
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
            menuMaxHeight: 300,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
            dropdownColor: dropdownColor,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            selectedItemBuilder: (BuildContext context) {
              return items.map<Widget>((String item) {
                return Text(
                  item,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }
}
