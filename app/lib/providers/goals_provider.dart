import 'package:flutter/foundation.dart';

/// Stubbed out - no goals API needed for fully offline app.
class GoalsProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    // No-op: offline app
  }
}
