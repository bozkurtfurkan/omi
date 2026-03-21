import 'package:flutter/foundation.dart';

/// Stubbed out - no cloud sync needed for fully offline app.
/// WAL sync functionality will be replaced with local storage in Task 6.
class SyncProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get isSyncing => false;
  bool get syncCompleted => false;

  int missingWalsOnDevice = 0;
  int missingWalsInSeconds = 0;
  Duration totalDuration = Duration.zero;

  Future<void> initialize() async {
    // No-op: offline app
  }

  void seekToPosition(Duration position) {
    // No-op: offline app
  }
}
