import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rak_app/core/models/admin_user_models.dart';
import 'package:rak_app/core/services/admin_user_service.dart';

/// Custom search widget with dropdown suggestions for user search
class UserSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String inflCode) onUserSelected;
  final bool includeInactive;
  final String? areaFilter;
  final bool isLoading;

  const UserSearchWidget({
    super.key,
    required this.controller,
    required this.onUserSelected,
    this.hintText = 'Search by Name (First, Middle, Last, or ID Holder)',
    this.includeInactive = false,
    this.areaFilter,
    this.isLoading = false,
  });

  @override
  State<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends State<UserSearchWidget> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  
  List<UserSearchSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_suggestions.isNotEmpty) {
        _showOverlay();
      }
    } else {
      // Delay hiding to allow for tap on suggestion
      Future.delayed(const Duration(milliseconds: 150), () {
        _hideOverlay();
      });
    }
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    
    if (query == _lastQuery) return;
    _lastQuery = query;

    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      _hideOverlay();
      return;
    }

    if (query.length < 2) {
      return; // Wait for at least 2 characters
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await AdminUserService.searchUsers(
        query: query,
        limit: 10,
        includeInactive: widget.includeInactive,
        area: widget.areaFilter,
      );

      if (mounted) {
        setState(() {
          _suggestions = response.data;
          _isSearching = false;
        });

        if (_suggestions.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
        _hideOverlay();
      }
    }
  }

  void _showOverlay() {
    _hideOverlay(); // Remove existing overlay first

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getTextFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 56.h), // Position below the text field
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 300.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getTextFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300.w;
  }

  Widget _buildSuggestionsList() {
    if (_isSearching) {
      return Container(
        height: 60.h,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8.w),
            const Text('Searching...'),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Container(
        height: 60.h,
        alignment: Alignment.center,
        child: Text(
          'No users found',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: 4.h),
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => Divider(
        height: 1.h,
        color: Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _buildSuggestionItem(suggestion);
      },
    );
  }

  Widget _buildSuggestionItem(UserSearchSuggestion suggestion) {
    return InkWell(
      onTap: () {
        widget.controller.text = suggestion.value;
        _hideOverlay();
        _focusNode.unfocus();
        widget.onUserSelected(suggestion.value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
            if (suggestion.subLabel != null) ...[
              SizedBox(height: 2.h),
              Text(
                suggestion.subLabel!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
          ),
          suffixIcon: widget.isLoading
              ? Container(
                  width: 20.w,
                  height: 20.h,
                  padding: EdgeInsets.all(12.w),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : _isSearching
                  ? Container(
                      width: 20.w,
                      height: 20.h,
                      padding: EdgeInsets.all(12.w),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
        onFieldSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _hideOverlay();
            widget.onUserSelected(value.trim());
          }
        },
      ),
    );
  }
}