import 'package:flutter/material.dart';

/// Stubbed out - no user management needed for fully offline app.
class UserProvider with ChangeNotifier {
  String _dataProtectionLevel = 'standard';
  bool _isLoading = false;

  String get dataProtectionLevel => _dataProtectionLevel;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    // No-op: offline app
  }
}
