import 'package:flutter/material.dart';

/// Stubbed out - no integrations needed for fully offline app.
class IntegrationProvider extends ChangeNotifier {
  final Map<String, bool> _integrations = {};
  bool _isLoading = false;
  bool _hasLoaded = false;

  Map<String, bool> get integrations => _integrations;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<void> loadIntegrations() async {
    // No-op: offline app
  }

  bool isEnabled(String key) => false;

  Future<void> loadFromBackend() async {
    // No-op: offline app
  }
}
