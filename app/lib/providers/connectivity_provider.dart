import 'package:flutter/material.dart';

/// Stubbed out - connectivity service deleted for fully offline app.
class ConnectivityProvider extends ChangeNotifier {
  bool _isConnected = true;
  bool _previousConnection = true;
  bool _isInitialized = true;

  bool get isConnected => _isConnected;
  bool get previousConnection => _previousConnection;
  bool get isInitialized => _isInitialized;

  void setConnected(bool value) {
    _previousConnection = _isConnected;
    _isConnected = value;
    notifyListeners();
  }

  static void showNoInternetDialog(BuildContext context) {
    // No-op: offline app always works offline
  }
}
