import 'package:flutter/material.dart';

/// Stubbed out - no dev API keys needed for fully offline app.
class DevApiKeyProvider with ChangeNotifier {
  List<dynamic> _keys = [];
  List<dynamic> get keys => _keys;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadKeys() async {
    // No-op: offline app
  }
}
