import 'package:just_audio/just_audio.dart';

import 'package:omi/providers/base_provider.dart';

/// Stubbed out - speech profile API removed for fully offline app.
class UserSpeechSamplesProvider extends BaseProvider {
  List<String> samplesUrl = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? currentPlayingIndex;
  bool isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  init() async {
    loading = true;
    notifyListeners();
    // TODO: backend removed - getUserSpeechProfile / getExpandedProfileSamples
    loading = false;
    notifyListeners();
  }
}
