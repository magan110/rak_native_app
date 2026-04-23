import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

/// Centralized location service for the app
/// Handles permission requests and location fetching
class LocationService {
  static final AppLogger _logger = AppLogger();
  static Position? _lastKnownPosition;
  static bool _permissionRequested = false;

  /// Request location permission at app start
  static Future<bool> requestLocationPermission() async {
    _logger.debug('requestLocationPermission called');
    
    if (_permissionRequested) {
      _logger.debug('Permission already requested, checking status');
      return await hasPermission();
    }

    _permissionRequested = true;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _logger.debug('Service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        _logger.warning('Location services are disabled');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      _logger.debug('Current permission: $permission');

      // Request permission if denied
      if (permission == LocationPermission.denied) {
        _logger.debug('Requesting permission...');
        permission = await Geolocator.requestPermission();
        _logger.debug('Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          _logger.warning('Permission denied by user');
          return false;
        }
      }

      // Check if permanently denied
      if (permission == LocationPermission.deniedForever) {
        _logger.warning('Permission permanently denied');
        return false;
      }

      _logger.info('Permission granted successfully');
      return true;
    } catch (e) {
      _logger.error('Error requesting permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  static Future<bool> hasPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    _logger.debug('getCurrentLocation called');
    
    try {
      // Check if services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _logger.debug('Service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        _logger.warning('Returning cached position (service disabled)');
        return _lastKnownPosition;
      }

      // Check permission
      bool hasPermission = await LocationService.hasPermission();
      _logger.debug('Has permission: $hasPermission');
      
      if (!hasPermission) {
        _logger.debug('No permission, requesting...');
        bool granted = await requestLocationPermission();
        if (!granted) {
          _logger.warning('Permission not granted, returning cached');
          return _lastKnownPosition;
        }
      }

      // Get current position
      _logger.debug('Fetching current position...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _logger.debug('Position obtained: ${position.latitude}, ${position.longitude}');
      _lastKnownPosition = position;
      return position;
    } catch (e) {
      _logger.error('Error getting location: $e');
      return _lastKnownPosition;
    }
  }

  /// Get last known location (cached)
  static Position? getLastKnownLocation() {
    return _lastKnownPosition;
  }

  /// Get latitude as string with 6 decimal places
  static String? getLatitudeString() {
    return _lastKnownPosition?.latitude.toStringAsFixed(6);
  }

  /// Get longitude as string with 6 decimal places
  static String? getLongitudeString() {
    return _lastKnownPosition?.longitude.toStringAsFixed(6);
  }

  /// Clear cached location
  static void clearCache() {
    _lastKnownPosition = null;
  }

  /// Open app settings for location permission
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
