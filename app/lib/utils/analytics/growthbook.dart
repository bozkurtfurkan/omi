import 'package:omi/utils/logger.dart';

/// Stubbed GrowthbookUtil - no Growthbook for offline app.
class GrowthbookUtil {
  static final GrowthbookUtil _instance = GrowthbookUtil._internal();

  factory GrowthbookUtil() {
    return _instance;
  }

  GrowthbookUtil._internal();

  static Future<void> init() async {
    // No-op: offline app
    Logger.debug('GrowthbookUtil init (stubbed)');
  }

  bool displayOmiFeedback() {
    return false;
  }

  bool displayMemoriesSearchBar() {
    return false;
  }

  bool isOmiFeedbackEnabled() {
    return false;
  }
}
