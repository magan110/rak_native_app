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
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text(
              hint ?? 'Select $label',
              style: TextStyle(
                color: Colors.grey[400],
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
                  ? Icon(actualIcon, color: Colors.grey[600], size: 20)
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
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            dropdownColor: Colors.white,
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
        ),
      ],
    );
  }
}
