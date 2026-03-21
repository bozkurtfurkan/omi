import 'package:flutter/material.dart';

/// Stubbed out - no calendar integration needed for fully offline app.
class CalendarProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    // No-op: offline app
  }
}
