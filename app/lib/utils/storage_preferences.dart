import 'package:shared_preferences/shared_preferences.dart';

const _keySaveAudio = 'local_save_audio';

class StoragePreferences {
  final bool saveAudio;
  const StoragePreferences({required this.saveAudio});

  static Future<StoragePreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return StoragePreferences(
      saveAudio: prefs.getBool(_keySaveAudio) ?? false,
    );
  }

  static Future<void> setSaveAudio(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySaveAudio, value);
  }
}
