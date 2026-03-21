import 'package:flutter/material.dart';

/// Stubbed out - no task integrations needed for fully offline app.
class TaskIntegrationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    // No-op: offline app
  }

  Future<void> loadFromBackend() async {
    // No-op: offline app
  }
}
