import 'package:flutter/material.dart';

/// Stubbed out - no MCP API needed for fully offline app.
class McpProvider with ChangeNotifier {
  List<dynamic> _keys = [];
  List<dynamic> get keys => _keys;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadKeys() async {
    // No-op: offline app
  }

  Future<void> fetchKeys() async {
    // No-op: offline app
  }
}
