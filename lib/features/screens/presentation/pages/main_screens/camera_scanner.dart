import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scanLineController;
  late AnimationController _cornerPulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _cornerPulseAnimation;

  bool isScanning = false;
  bool _isProcessingQR = false;
  bool _cameraInitialized = false;
  bool _permissionGranted = false;

  MobileScannerController? _scannerController;

  final List<Map<String, dynamic>> _scannedQRCodes = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestCameraPermission();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _cornerPulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6),
      ),
    );

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _cornerPulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _cornerPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanLineController.dispose();
    _cornerPulseController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();

      if (status == PermissionStatus.granted) {
        setState(() {
          _permissionGranted = true;
          _cameraInitialized = true;
        });
        _initializeScanner();
      } else if (status == PermissionStatus.permanentlyDenied) {
        _showError(
          'Camera permission is permanently denied. Please enable it in settings.',
        );
      } else {
        _showError('Camera permission is required to scan QR codes.');
      }
    } catch (e) {
      _showError('Failed to request camera permission: $e');
    }
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Start scanning
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => isScanning = true);
      }
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    
    if (!_isProcessingQR && barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        _handleQRCode(barcode.rawValue!);
      }
    }
  }

  void _handleQRCode(String code) {
    if (_isProcessingQR) return;

    setState(() => _isProcessingQR = true);

    HapticFeedback.heavyImpact();

    final type = _detectQRType(code);

    setState(() {
      _scannedQRCodes.insert(0, {
        'data': code,
        'type': type,
        'timestamp': DateTime.now(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8.w),
            const Text('QR Code scanned'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Resume scanning after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isProcessingQR = false);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _detectQRType(String code) {
    if (code.startsWith('http://') || code.startsWith('https://')) return 'URL';
    if (code.startsWith('mailto:')) return 'Email';
    if (code.startsWith('tel:')) return 'Phone';
    if (code.startsWith('WIFI:')) return 'WiFi';
    if (code.startsWith('BEGIN:VCARD')) return 'Contact';
    if (code.contains('\n') &&
        (code.contains('Name:') || code.contains('ID:'))) {
      return 'Product Info';
    }
    return 'Text';
  }

  IconData _getQRIcon(String type) {
    switch (type) {
      case 'URL':
        return Icons.link;
      case 'Email':
        return Icons.email;
      case 'Phone':
        return Icons.phone;
      case 'WiFi':
        return Icons.wifi;
      case 'Contact':
        return Icons.contact_page;
      case 'Product Info':
        return Icons.inventory;
      default:
        return Icons.text_fields;
    }
  }

  void _processQRData(String code, String type) {
    try {
      switch (type) {
        case 'URL':
          // For mobile, you might want to use url_launcher package
          _showError('URL detected: $code');
          break;
        case 'Email':
          _showError('Email detected: $code');
          break;
        case 'Phone':
          _showError('Phone detected: $code');
          break;
        default:
          _showError('QR code processed successfully');
      }
    } catch (_) {
      _showError('Unable to process QR code');
    }
  }

  void _clearScannedList() => setState(() => _scannedQRCodes.clear());

  void _toggleFlash() {
    _scannerController?.toggleTorch();
  }

  void _flipCamera() {
    _scannerController?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: Text(
          'QR Code Scanner',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scanner section
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade800,
                    Colors.blue.shade600,
                    Colors.blue.shade400,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _cameraInitialized && _permissionGranted
                        ? _buildQRView()
                        : _buildInitializing(),
                  ),
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildOverlay(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scanned list section
          Expanded(flex: 1, child: _buildScannedList()),
        ],
      ),
    );
  }

  Widget _buildQRView() {
    return MobileScanner(
      controller: _scannerController,
      onDetect: _onDetect,
    );
  }

  Widget _buildInitializing() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              _permissionGranted
                  ? 'Initializing camera...'
                  : 'Requesting camera permission...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.h),
            if (!_permissionGranted)
              ElevatedButton(
                onPressed: _requestCameraPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: const Text('Grant Permission'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      'QR Code Scanner',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Flash toggle button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _toggleFlash,
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Camera flip button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _flipCamera,
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 280.w,
                height: 280.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corners
                    ...List.generate(4, (index) {
                      final alignments = [
                        Alignment.topLeft,
                        Alignment.topRight,
                        Alignment.bottomLeft,
                        Alignment.bottomRight,
                      ];
                      return Align(
                        alignment: alignments[index],
                        child: AnimatedBuilder(
                          animation: _cornerPulseAnimation,
                          builder: (_, __) {
                            return Transform.scale(
                              scale: _cornerPulseAnimation.value,
                              child: Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: index < 2
                                        ? const BorderSide(
                                            color: Colors.white,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                    bottom: index >= 2
                                        ? const BorderSide(
                                            color: Colors.white,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                    left: index % 2 == 0
                                        ? const BorderSide(
                                            color: Colors.white,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                    right: index % 2 == 1
                                        ? const BorderSide(
                                            color: Colors.white,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    // Scan line
                    if (isScanning && !_isProcessingQR)
                      AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (_, __) {
                          return Positioned(
                            top: 280.w * _scanLineAnimation.value - 1,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // Center icon
                    if (isScanning)
                      Center(
                        child: Container(
                          width: 70.w,
                          height: 70.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 35.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Text(
                  _cameraInitialized && isScanning && !_isProcessingQR
                      ? 'Position QR code within the frame'
                      : _cameraInitialized && isScanning
                      ? 'Processing QR code...'
                      : _cameraInitialized
                      ? 'Camera ready - scan QR code'
                      : 'Starting camera...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Scanned QR Codes',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ),
                if (_scannedQRCodes.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: TextButton.icon(
                      onPressed: _clearScannedList,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade600,
                        size: 20.sp,
                      ),
                      label: Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _scannedQRCodes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24.w),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.qr_code_scanner_outlined,
                            color: Colors.blue.shade300,
                            size: 48.sp,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'No QR codes scanned yet',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Scan a QR code to see it here',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: _scannedQRCodes.length,
                    itemBuilder: (context, index) {
                      final qr = _scannedQRCodes[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        child: Card(
                          elevation: 3,
                          shadowColor: Colors.blue.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: InkWell(
                            onTap: () => _processQRData(qr['data'], qr['type']),
                            borderRadius: BorderRadius.circular(16.r),
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: Icon(
                                          _getQRIcon(qr['type']),
                                          color: Colors.blue.shade600,
                                          size: 24.sp,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              qr['type'],
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade600,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              _formatTime(qr['timestamp']),
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Container(
                                    padding: EdgeInsets.all(12.w),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      qr['data'],
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: const Color(0xFF2C3E50),
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: qr['data']),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Copied to clipboard'),
                                                ],
                                              ),
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.copy,
                                          size: 18.sp,
                                          color: Colors.blue.shade600,
                                        ),
                                        label: Text(
                                          'Copy',
                                          style: TextStyle(
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 8.h,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                            side: BorderSide(
                                              color: Colors.blue.shade200,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      ElevatedButton.icon(
                                        onPressed: () => _processQRData(
                                          qr['data'],
                                          qr['type'],
                                        ),
                                        icon: Icon(
                                          Icons.open_in_new,
                                          size: 18.sp,
                                        ),
                                        label: const Text('Open'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 10.h,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
