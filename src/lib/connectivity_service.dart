import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker.createInstance(); // 🟢 Corrected initialization
  late StreamSubscription _subscription;

  final StreamController<bool> _connectionStatus = StreamController<bool>.broadcast();

  ConnectivityService() {
    _init();
    _startListening();
  }

  void _init() async {
    final hasConnection = await _connectionChecker.hasConnection;
    _connectionStatus.add(hasConnection);
  }

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) async {
      final hasConnection = await _connectionChecker.hasConnection;
      _connectionStatus.add(hasConnection);
    });
  }

  Stream<bool> get connectionStatus => _connectionStatus.stream;

  Future<bool> checkConnection() => _connectionChecker.hasConnection;

  void dispose() {
    _subscription.cancel();
    _connectionStatus.close();
  }
}