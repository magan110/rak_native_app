/// Network Information Interface
/// Check network connectivity
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementation using connectivity_plus package
/// Uncomment and use after adding connectivity_plus to pubspec.yaml
/*
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  
  NetworkInfoImpl(this.connectivity);
  
  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
*/
