import 'package:flutter/foundation.dart';

import 'package:omi/models/announcement.dart';
import 'package:omi/providers/base_provider.dart';

/// Stubbed out - no announcements needed for fully offline app.
class AnnouncementProvider extends BaseProvider {
  List<Announcement> _pendingAnnouncements = [];
  List<Announcement> get pendingAnnouncements => _pendingAnnouncements;

  Future<bool> fetchPendingAnnouncements({
    String? trigger,
    String? firmwareVersion,
    String? deviceModel,
  }) async {
    // No-op: offline app
    return false;
  }

  Future<void> fetchAnnouncements({String trigger = 'app_open'}) async {
    // No-op: offline app
  }

  Future<void> dismissAnnouncement(String id) async {
    // No-op: offline app
  }

  Future<void> markAnnouncementDismissed(String id, {bool ctaClicked = false}) async {
    // No-op: offline app
  }
}
