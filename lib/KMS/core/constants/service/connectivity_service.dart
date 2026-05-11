import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectionStatusController;

  Stream<bool> get connectionStream {
    _connectionStatusController ??= StreamController<bool>.broadcast();
    return _connectionStatusController!.stream;
  }

  bool _isConnected = true;
  bool get isConnected => _isConnected;
  Future<void> initialize() async {
    _isConnected = await checkConnection();
    
    _connectivity.onConnectivityChanged.listen((result) async {
      final bool connected = await checkConnection();
      if (_isConnected != connected) {
        _isConnected = connected;
        _connectionStatusController?.add(connected);
      }
    });
  }

  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectionStatusController?.close();
  }
}
