import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../utils/logger.dart';

/// SSL-enabled HTTP client factory
/// Loads the SSL certificate from assets and creates an HTTP client
/// that uses the certificate for all HTTPS connections
class SslHttpClient {
  static http.Client? _client;
  static SecurityContext? _securityContext;
  static final AppLogger _logger = AppLogger();

  /// Allowed host pattern for certificate acceptance
  static bool _isAllowedHost(String host) {
    return host.contains('birlawhite.com');
  }

  /// Get or create the SSL-enabled HTTP client
  /// This client will use the certificate from assets/cert/rak_cer.pem
  static Future<http.Client> getClient() async {
    if (_client != null) {
      return _client!;
    }

    try {
      // Load the certificate from assets
      final certificateBytes = await rootBundle.load('assets/cert/rak_cer.pem');
      final certificate = certificateBytes.buffer.asUint8List();

      _logger.debug('SSL Certificate loaded (${certificate.length} bytes)');

      // Create security context with the certificate
      _securityContext = SecurityContext();
      _securityContext!.setTrustedCertificatesBytes(certificate);

      // Create HttpClient with the security context and enhanced settings
      final httpClient = HttpClient(context: _securityContext);
      
      // Configure HTTP client for SSL handling — allow only birlawhite.com
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        _logger.warning('Bad certificate callback for $host:$port');
        if (_isAllowedHost(host)) {
          return true;
        }
        return false;
      };
      
      // Set connection timeout
      httpClient.connectionTimeout = const Duration(seconds: 30);
      
      // Set idle timeout
      httpClient.idleTimeout = const Duration(seconds: 30);

      // Create IOClient that wraps the HttpClient
      _client = IOClient(httpClient);

      _logger.debug('SSL-enabled HTTP client created successfully');
      return _client!;
    } catch (e) {
      // If certificate loading fails, create a client with domain-restricted callback
      _logger.warning('Failed to load SSL certificate: $e');
      _logger.warning('Creating fallback HTTP client with domain-restricted validation');
      
      try {
        final httpClient = HttpClient();
        
        // Fallback callback — still restricted to birlawhite.com only
        httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
          _logger.warning('Fallback certificate validation for $host:$port');
          if (_isAllowedHost(host)) {
            return true;
          }
          _logger.error('Rejecting certificate for $host');
          return false;
        };
        
        // Set timeouts
        httpClient.connectionTimeout = const Duration(seconds: 30);
        httpClient.idleTimeout = const Duration(seconds: 30);
        
        _client = IOClient(httpClient);
        _logger.debug('Fallback HTTP client created successfully');
        return _client!;
      } catch (fallbackError) {
        _logger.error('Fallback client creation failed: $fallbackError');
        _client = http.Client();
        return _client!;
      }
    }
  }

  /// Create a new SSL-enabled HTTP client instance
  /// Use this if you need a fresh client instance
  static Future<http.Client> createClient() async {
    try {
      // Load the certificate from assets
      final certificateBytes = await rootBundle.load('assets/cert/rak_cer.pem');
      final certificate = certificateBytes.buffer.asUint8List();

      // Create security context with the certificate
      final securityContext = SecurityContext();
      securityContext.setTrustedCertificatesBytes(certificate);

      // Create HttpClient with the security context
      final httpClient = HttpClient(context: securityContext);
      
      // Configure certificate callback — allow only birlawhite.com
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return _isAllowedHost(host);
      };
      
      // Set timeouts
      httpClient.connectionTimeout = const Duration(seconds: 30);
      httpClient.idleTimeout = const Duration(seconds: 30);

      // Create IOClient that wraps the HttpClient
      return IOClient(httpClient);
    } catch (e) {
      _logger.warning('Failed to create SSL client: $e');
      
      // Fallback with domain-restricted certificate validation
      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return _isAllowedHost(host);
      };
      httpClient.connectionTimeout = const Duration(seconds: 30);
      httpClient.idleTimeout = const Duration(seconds: 30);
      
      return IOClient(httpClient);
    }
  }

  /// Dispose the client and free resources
  static void dispose() {
    _client?.close();
    _client = null;
    _securityContext = null;
  }

  /// Check if the client is initialized
  static bool get isInitialized => _client != null;
  
  /// Test SSL connection to the server
  static Future<bool> testConnection(String url) async {
    try {
      final client = await getClient();
      final response = await client.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      
      _logger.debug('SSL test connection to $url: ${response.statusCode}');
      return response.statusCode < 500;
    } catch (e) {
      _logger.error('SSL test connection failed: $e');
      return false;
    }
  }
}
