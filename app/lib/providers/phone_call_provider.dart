import 'package:flutter/material.dart';

import 'package:omi/backend/schema/phone_call.dart';
import 'package:omi/backend/schema/transcript_segment.dart';

/// Stubbed out - phone call transcription requires backend WebSocket.
class PhoneCallProvider extends ChangeNotifier {
  PhoneCallState _state = PhoneCallState.idle;
  List<TranscriptSegment> _segments = [];
  bool _isLoading = false;

  PhoneCallState get state => _state;
  List<TranscriptSegment> get segments => _segments;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    // No-op: offline app
  }
}
