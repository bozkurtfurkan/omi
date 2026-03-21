import 'package:flutter/material.dart';

/// Stubbed out - no usage tracking needed for fully offline app.
class UsageProvider with ChangeNotifier {
  bool isLoading = false;

  dynamic subscription;

  Future<void> initialize() async {
    // No-op: offline app
  }

  Future<void> fetchSubscription() async {
    // No-op: offline app
  }
}
