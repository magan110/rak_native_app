import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import '../../core/utils/responsive_utils.dart';

class FileUploadWidget extends StatefulWidget {
  final String label;
  final IconData icon;
  final Function(String?) onFileSelected;
  final Duration delay;
  final bool isRequired;
  final List<String> allowedExtensions;
  final double maxSizeInMB;
  final String? currentFilePath;
  final String? formType; // 'contractor' or 'painter' get a simplified picker

  const FileUploadWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.onFileSelected,
    this.delay = Duration.zero,
    this.isRequired = true,
    this.allowedExtensions = const ['*'],
    this.maxSizeInMB = 15.0,
    this.currentFilePath,
    this.formType,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget>
    with SingleTickerProviderStateMixin {
  String? _selectedFilePath;
  String? _originalFileName;
  String? _fileType; // captured type hint for UI (does NOT control detection)
  bool _isVisible = false;
  bool _isUploading = false;
  bool _isUploaded = false;
  String? _uploadError;

  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _progressAnimation;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();

    _selectedFilePath = widget.currentFilePath;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _isVisible = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void didUpdateWidget(FileUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFilePath != oldWidget.currentFilePath) {
      setState(() {
        _selectedFilePath = widget.currentFilePath;
        if (_selectedFilePath != null && _selectedFilePath!.isNotEmpty) {
          _isUploading = false;
          _isUploaded = true;
          _uploadError = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _scaffoldMessenger = null;
    super.dispose();
  }

  bool _isContractorOrPainterForm() =>
      widget.formType == 'contractor' || widget.formType == 'painter';

  void _safeShowSnackBar(SnackBar bar) {
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.showSnackBar(bar);
    }
  }

  void _safeHideCurrentSnackBar() {
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cardHeight = ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 160.0,
      tablet: 150.0,
      desktop: 140.0,
    );

    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.isRequired ? '${widget.label} *' : widget.label,
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Max ${widget.maxSizeInMB}MB',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 10,
                        tablet: 11,
                        desktop: 11,
                      ),
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ScaleTransition(
              scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
              child: GestureDetector(
                onTapDown: (_) => _animationController?.forward(),
                onTapUp: (_) => _animationController?.reverse(),
                onTapCancel: () => _animationController?.reverse(),
                onTap: _selectedFilePath == null
                    ? () => _showUploadOptions(context)
                    : () => _showFileActions(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height:
                      cardHeight, // BOUNDED HEIGHT ← fixes infinite-height issue
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: _selectedFilePath != null
                        ? LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [Colors.grey.shade50, Colors.grey.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: _selectedFilePath != null
                          ? Colors.blue.shade200
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: _selectedFilePath != null
                      ? _buildUploadedFileDisplay()
                      : _buildUploadPrompt(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtils.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 16.0,
          desktop: 20.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              width: ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 50.0,
                tablet: 60.0,
                desktop: 70.0,
              ),
              height: ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 50.0,
                tablet: 60.0,
                desktop: 70.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 24.0,
                  tablet: 28.0,
                  desktop: 32.0,
                ),
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 8.0,
              tablet: 10.0,
              desktop: 12.0,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Tap to upload ${widget.label.toLowerCase()}',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 14,
                  ),
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 6.0,
              tablet: 8.0,
              desktop: 10.0,
            ),
          ),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 8.0,
              ),
              runSpacing: ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 8.0,
              ),
              children: [
                _buildUploadMethodChip(Icons.camera_alt, 'Camera'),
                _buildUploadMethodChip(Icons.photo_library, 'Gallery'),
                _buildUploadMethodChip(Icons.folder, 'Files'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadMethodChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveValue(
          context,
          mobile: 8.0,
          tablet: 10.0,
          desktop: 12.0,
        ),
        vertical: ResponsiveUtils.getResponsiveValue(
          context,
          mobile: 4.0,
          tablet: 5.0,
          desktop: 6.0,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 14.0,
              tablet: 15.0,
              desktop: 16.0,
            ),
            color: Colors.blue.shade600,
          ),
          SizedBox(
            width: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 4.0,
              tablet: 5.0,
              desktop: 6.0,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 12,
              ),
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFileDisplay() {
    final isImage = _isImageFileLocal(_selectedFilePath!);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: isImage ? _buildImagePreview() : _buildFileIconForUploadArea(),
        ),
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      value: _progressAnimation?.value,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Uploading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ),
        if (!_isUploading)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_uploadError != null)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 16,
                        ),
                      )
                    else if (_isUploaded)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.attach_file,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _getFileNameLocal(_selectedFilePath!),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 14,
                          ),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _uploadError != null
                      ? 'Upload failed'
                      : _isUploaded
                      ? 'Upload complete'
                      : 'Ready to upload',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 11,
                      tablet: 12,
                      desktop: 12,
                    ),
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        if (!_isUploading)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _showFileActions(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedFilePath == null || _selectedFilePath == 'mock_file_path') {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Image Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final file = File(_selectedFilePath!);

    return Container(
      color: Colors.grey.shade200,
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 50, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Unable to load image',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileIconForUploadArea() {
    if (_selectedFilePath == null || _selectedFilePath == 'mock_file_path') {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description,
                  size: 30,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'DOCUMENT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final extension = _getFileExtensionLocal(_selectedFilePath!).toLowerCase();

    if (extension == 'pdf') {
      return FutureBuilder<PdfDocument>(
        future: PdfDocument.openFile(_selectedFilePath!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return FutureBuilder<PdfPage>(
              future: snapshot.data!.getPage(1),
              builder: (context, pageSnapshot) {
                if (pageSnapshot.connectionState == ConnectionState.done &&
                    pageSnapshot.hasData) {
                  // SAFE DIMENSION GUARD to prevent 1x1/0x0 allocations
                  final pw = pageSnapshot.data!.width;
                  final ph = pageSnapshot.data!.height;
                  final double safeW = (pw != null && pw > 10)
                      ? pw.toDouble() * 2.0
                      : 800.0;
                  final double safeH = (ph != null && ph > 10)
                      ? ph.toDouble() * 2.0
                      : 1200.0;

                  return FutureBuilder<PdfPageImage?>(
                    future: pageSnapshot.data!.render(
                      width: safeW,
                      height: safeH,
                    ),
                    builder: (context, imageSnapshot) {
                      if (imageSnapshot.connectionState ==
                              ConnectionState.done &&
                          imageSnapshot.hasData &&
                          imageSnapshot.data != null) {
                        return Container(
                          color: Colors.grey.shade100,
                          child: Image.memory(
                            imageSnapshot.data!.bytes,
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                      return _buildDocumentIconFallback(extension);
                    },
                  );
                }
                return _buildDocumentIconFallback(extension);
              },
            );
          }
          return _buildDocumentIconFallback(extension);
        },
      );
    }

    return _buildDocumentIconFallback(extension);
  }

  Widget _buildDocumentIconFallback(String extension) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getFileIconLocal(_selectedFilePath!),
                size: 30,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              extension.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File Options',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFileNameLocal(_selectedFilePath!),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  _buildActionOption(
                    icon: Icons.visibility_rounded,
                    title: 'View File',
                    subtitle: 'Preview the uploaded file',
                    onTap: () {
                      Navigator.pop(context);
                      _showFilePreview();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_uploadError != null) ...[
                    _buildActionOption(
                      icon: Icons.refresh_rounded,
                      title: 'Retry Upload',
                      subtitle: 'Try uploading the file again',
                      onTap: () {
                        Navigator.pop(context);
                        _retryUpload();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildActionOption(
                    icon: Icons.edit_rounded,
                    title: 'Change File',
                    subtitle: 'Upload a different file',
                    onTap: () {
                      Navigator.pop(context);
                      _showUploadOptions(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionOption(
                    icon: Icons.delete_rounded,
                    title: 'Remove File',
                    subtitle: 'Delete this uploaded file',
                    onTap: () {
                      Navigator.pop(context);
                      _removeFile();
                    },
                    isDestructive: true,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 14.0,
            tablet: 16.0,
            desktop: 18.0,
          ),
        ),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: isDestructive ? Border.all(color: Colors.red.shade100) : null,
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 48.0,
                tablet: 50.0,
                desktop: 52.0,
              ),
              height: ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 48.0,
                tablet: 50.0,
                desktop: 52.0,
              ),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.shade100 : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? Colors.red.shade600
                    : Colors.blue.shade600,
                size: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 22.0,
                  tablet: 24.0,
                  desktop: 26.0,
                ),
              ),
            ),
            SizedBox(
              width: ResponsiveUtils.getResponsiveValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 15,
                        tablet: 16,
                        desktop: 16,
                      ),
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Colors.red.shade700
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 14,
                      ),
                      color: isDestructive
                          ? Colors.red.shade500
                          : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload ${widget.label}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to upload your file',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  if (_isContractorOrPainterForm()) ...[
                    _buildUploadOption(
                      icon: Icons.camera_alt_rounded,
                      title: 'Take Photo',
                      subtitle: 'Use camera to capture',
                      onTap: () => _pickFromCamera(context),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      icon: Icons.photo_library_rounded,
                      title: 'Choose from Gallery',
                      subtitle: 'Select from photo library (Recommended)',
                      onTap: () => _pickFromGallery(context),
                      isRecommended: true,
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      icon: Icons.folder_rounded,
                      title: 'Browse Files',
                      subtitle: 'Select PDF or other files from device',
                      onTap: () => _pickFromFiles(context),
                    ),
                  ] else ...[
                    _buildUploadOption(
                      icon: Icons.camera_alt_rounded,
                      title: 'Take Photo',
                      subtitle: 'Use camera to capture',
                      onTap: () => _pickFromCamera(context),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      icon: Icons.photo_library_rounded,
                      title: 'Choose from Gallery',
                      subtitle: 'Select from photo library',
                      onTap: () => _pickFromGallery(context),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      icon: Icons.folder_rounded,
                      title: 'Choose from Files',
                      subtitle: 'Select from device storage',
                      onTap: () => _pickFromFiles(context),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'File Requirements',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Supported: ${widget.allowedExtensions.contains('*') ? 'All file types' : widget.allowedExtensions.join(', ').toUpperCase()}\n'
                          'Max size: ${widget.maxSizeInMB}MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? warning,
    bool isRecommended = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 14.0,
            tablet: 16.0,
            desktop: 18.0,
          ),
        ),
        decoration: BoxDecoration(
          color: isRecommended ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: isRecommended
              ? Border.all(color: Colors.green.shade200, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 48.0,
                    tablet: 50.0,
                    desktop: 52.0,
                  ),
                  height: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 48.0,
                    tablet: 50.0,
                    desktop: 52.0,
                  ),
                  decoration: BoxDecoration(
                    color: isRecommended ? Colors.green.shade100 : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: isRecommended
                        ? Colors.green.shade600
                        : Colors.blue.shade600,
                    size: ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 22.0,
                      tablet: 24.0,
                      desktop: 26.0,
                    ),
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                ),
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
                                  mobile: 15,
                                  tablet: 16,
                                  desktop: 16,
                                ),
                                fontWeight: FontWeight.w600,
                                color: warning != null
                                    ? Colors.orange.shade800
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 14,
                          ),
                          color: warning != null
                              ? Colors.orange.shade700
                              : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 15.0,
                    desktop: 16.0,
                  ),
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            if (warning != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning,
                      size: ResponsiveUtils.getResponsiveValue(
                        context,
                        mobile: 16.0,
                        tablet: 17.0,
                        desktop: 18.0,
                      ),
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 11,
                            tablet: 12,
                            desktop: 12,
                          ),
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    Navigator.pop(context);

    try {
      final cameraStatus = await Permission.camera.request();

      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        _safeShowSnackBar(
          SnackBar(
            content: const Text('Camera permission is required to take photos'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        final file = File(photo.path);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > widget.maxSizeInMB) {
          _safeShowSnackBar(
            SnackBar(
              content: Text(
                'File size exceeds ${widget.maxSizeInMB.toStringAsFixed(0)} MB limit',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        _processFile(photo.path, 'image', photo.name);
      }
    } catch (e) {
      _safeShowSnackBar(
        SnackBar(
          content: Text('Error capturing photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    Navigator.pop(context);

    try {
      final photosStatus = await Permission.photos.request();

      if (photosStatus.isDenied || photosStatus.isPermanentlyDenied) {
        _safeShowSnackBar(
          SnackBar(
            content: const Text(
              'Photo library permission is required to select images',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > widget.maxSizeInMB) {
          _safeShowSnackBar(
            SnackBar(
              content: Text(
                'File size exceeds ${widget.maxSizeInMB.toStringAsFixed(0)} MB limit',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        _processFile(image.path, 'image', image.name);
      }
    } catch (e) {
      _safeShowSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFromFiles(BuildContext context) async {
    Navigator.pop(context);

    try {
      PermissionStatus storageStatus;

      if (Platform.isAndroid) {
        if (await Permission.storage.request().isGranted) {
          storageStatus = PermissionStatus.granted;
        } else if (await Permission.photos.request().isGranted ||
            await Permission.videos.request().isGranted) {
          storageStatus = PermissionStatus.granted;
        } else {
          storageStatus = PermissionStatus.denied;
        }
      } else {
        storageStatus = await Permission.storage.request();
      }

      if (storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
        _safeShowSnackBar(
          SnackBar(
            content: const Text(
              'Storage permission is required to select files',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      // Pick file - show all file types (PDFs, images, documents, etc.)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        allowCompression: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final filePath = pickedFile.path;
        final fileName = pickedFile.name;

        if (filePath == null) {
          _safeShowSnackBar(
            const SnackBar(
              content: Text('Unable to access the selected file'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final file = File(filePath);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > widget.maxSizeInMB) {
          _safeShowSnackBar(
            SnackBar(
              content: Text(
                'File size exceeds ${widget.maxSizeInMB.toStringAsFixed(0)} MB limit',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final extension = fileName.split('.').last.toLowerCase();
        String fileType = 'document';
        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
          fileType = 'image';
        } else if (['pdf'].contains(extension)) {
          fileType = 'pdf';
        }

        _processFile(filePath, fileType, fileName);
      }
    } catch (e) {
      _safeShowSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _processFile(String filePath, String fileType, String fileName) {
    setState(() {
      _selectedFilePath = filePath;
      _fileType = fileType;
      _originalFileName = fileName;
      _isUploading = true;
      _isUploaded = false;
      _uploadError = null;
    });

    _animationController?.repeat();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _animationController?.stop();
        _animationController?.reset();

        setState(() {
          _isUploading = false;
          _isUploaded = true;
          _uploadError = null;
        });

        _showEnhancedSuccessSnackBar('${widget.label} uploaded successfully!');
        widget.onFileSelected(filePath);
      }
    });
  }

  void _simulateFileUpload(String fileType, String fileName) {
    setState(() {
      _selectedFilePath = 'mock_file_path';
      _fileType = fileType;
      _originalFileName = fileName;
      _isUploading = true;
      _isUploaded = false;
      _uploadError = null;
    });

    _animationController?.repeat();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _animationController?.stop();
        _animationController?.reset();

        setState(() {
          _isUploading = false;
          _isUploaded = true;
          _uploadError = null;
        });

        _showEnhancedSuccessSnackBar('${widget.label} uploaded successfully!');
        widget.onFileSelected('mock_file_key');
      }
    });
  }

  Future<void> _retryUpload() async {
    if (_selectedFilePath == null) return;
    _simulateFileUpload(
      _fileType ?? 'document',
      _originalFileName ?? 'file.jpg',
    );
  }

  void _removeFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Remove File'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${_getFileNameLocal(_selectedFilePath!)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedFilePath = null;
                _isUploading = false;
                _isUploaded = false;
                _uploadError = null;
              });
              widget.onFileSelected(null);
              _showSuccessSnackBar('File removed successfully');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    _safeShowSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEnhancedSuccessSnackBar(String message) {
    _safeShowSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Complete!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(message, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _safeShowSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showFilePreview() {
    if (_selectedFilePath == null) return;

    final isImage = _isImageFileLocal(_selectedFilePath!);
    if (isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(widget.label),
              actions: [
                IconButton(
                  onPressed: _showFileDetails,
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: _selectedFilePath != 'mock_file_path'
                    ? Image.file(
                        File(_selectedFilePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Unable to load image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : _buildFileIconForUploadArea(),
              ),
            ),
          ),
        ),
      );
    } else {
      _showDocumentViewer();
    }
  }

  void _showDocumentViewer() {
    if (_selectedFilePath == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(widget.label),
            actions: [
              IconButton(
                onPressed: _showFileDetails,
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
          body: _buildDocumentContent(),
        ),
      ),
    );
  }

  Widget _buildDocumentContent() {
    String fileType = _fileType ?? 'unknown';

    if (fileType == 'unknown') {
      final extension = _getFileExtensionLocal(
        _selectedFilePath!,
      ).toLowerCase();
      if (['pdf'].contains(extension)) {
        fileType = 'pdf';
      } else if (['txt'].contains(extension)) {
        fileType = 'text';
      } else if (['doc', 'docx'].contains(extension)) {
        fileType = 'word';
      } else if (['xls', 'xlsx'].contains(extension)) {
        fileType = 'excel';
      } else if (['ppt', 'pptx'].contains(extension)) {
        fileType = 'powerpoint';
      } else if ([
        'jpg',
        'jpeg',
        'png',
        'gif',
        'bmp',
        'webp',
      ].contains(extension)) {
        fileType = 'image';
      }
    }

    switch (fileType) {
      case 'pdf':
        return _buildPdfViewer();
      case 'text':
        return _buildDocumentPlaceholder('Text Document');
      case 'word':
        return _buildDocumentPlaceholder('Word Document');
      case 'excel':
        return _buildDocumentPlaceholder('Excel Spreadsheet');
      case 'powerpoint':
        return _buildDocumentPlaceholder('PowerPoint Presentation');
      case 'image':
        return _buildImagePlaceholder();
      default:
        return _buildUnsupportedDocument();
    }
  }

  Widget _buildPdfViewer() {
    if (_selectedFilePath == null || _selectedFilePath == 'mock_file_path') {
      return _buildDocumentPlaceholder('PDF Document');
    }

    return FutureBuilder<PdfDocument>(
      future: PdfDocument.openFile(_selectedFilePath!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading PDF',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to open this document',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildDocumentPlaceholder('PDF Document');
        }

        final pdfDocument = snapshot.data!;

        return PdfView(
          controller: PdfController(document: Future.value(pdfDocument)),
          onDocumentError: (error) {
            // ignore: avoid_print
            print('PDF Error: $error');
          },
        );
      },
    );
  }

  Widget _buildDocumentPlaceholder(String documentType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getFileIconLocal(_selectedFilePath!),
              size: 50,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            documentType,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getFileNameLocal(_selectedFilePath!),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ready to View',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 80, color: Colors.green.shade600),
                const SizedBox(height: 16),
                Text(
                  'Image File',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _originalFileName ?? _getFileNameLocal(_selectedFilePath!),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 30,
                ),
                const SizedBox(height: 12),
                Text(
                  _isUploaded
                      ? 'Image Uploaded Successfully'
                      : (_isUploading ? 'Uploading...' : 'Ready to Upload'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _uploadError == null
                      ? (_isUploaded
                            ? 'Your image has been uploaded and is ready for processing.'
                            : 'We will upload your image now.')
                      : 'Upload failed: $_uploadError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedDocument() {
    final ext = _getFileExtensionLocal(_selectedFilePath!).toUpperCase();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insert_drive_file,
              size: 50,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Unsupported File Type',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _originalFileName ?? _getFileNameLocal(_selectedFilePath!),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$ext files cannot be previewed',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.info_outline, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text(
                  'File Type Not Supported',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFileDetails() {
    if (_selectedFilePath == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getFileIconLocal(_selectedFilePath!), color: Colors.blue),
            const SizedBox(width: 8),
            const Text('File Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Label', widget.label),
            _buildDetailRow('Name', _getFileNameLocal(_selectedFilePath!)),
            _buildDetailRow(
              'Type',
              _getFileExtensionLocal(_selectedFilePath!).toUpperCase(),
            ),
            _buildDetailRow('Path', _getUserFriendlyPath(_selectedFilePath!)),
            _buildDetailRow('Size', '2.5 MB'), // Mock size
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_isImageFileLocal(_selectedFilePath!))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showFilePreview();
              },
              child: const Text('View Full Size'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // -------- Local helper methods (no globals!) --------

  String _getFileNameLocal(String path) {
    if (path.startsWith('data:')) {
      if (_originalFileName != null && _originalFileName!.isNotEmpty) {
        return _originalFileName!;
      }
      final mimeType = path.split(',')[0].split(':')[1].split(';')[0];
      final ext = mimeType.split('/').last;
      return 'uploaded_file.$ext';
    }
    return path.split('/').last;
  }

  String _getUserFriendlyPath(String path) {
    if (path.startsWith('data:')) {
      final mimeType = path.split(',')[0].split(':')[1].split(';')[0];
      return 'Data URL ($mimeType)';
    }
    if (path.length > 50) {
      return '${path.substring(0, 20)}...${path.substring(path.length - 20)}';
    }
    return path;
  }

  String _getFileExtensionLocal(String path) {
    if (!path.contains('.')) return 'jpg'; // sensible default for camera photos
    return path.split('.').last.toLowerCase();
  }

  bool _isImageFileLocal(String path) {
    final lower = path.toLowerCase();

    if (lower.startsWith('data:')) {
      final comma = lower.indexOf(',');
      final header = lower.substring(5, comma == -1 ? lower.length : comma);
      final mime = header.split(';').first;
      return mime.startsWith('image/');
    }

    final ext = _getFileExtensionLocal(path);
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'};
    return imageExts.contains(ext);
  }

  IconData _getFileIconLocal(String path) {
    final extension = _getFileExtensionLocal(path);
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }
}
