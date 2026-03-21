import 'package:flutter/cupertino.dart';

import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/person.dart';
import 'package:omi/providers/base_provider.dart';

/// Stripped of backend API calls for fully offline app.
class PeopleProvider extends BaseProvider {
  List<Person> people = SharedPreferencesUtil().cachedPeople;

  void initialize() {
    people = SharedPreferencesUtil().cachedPeople;
    notifyListeners();
  }

  bool isPlaying = false;
  int? currentPlayingIndex;
  int? currentPlayingPersonIndex;

  Future<void> refreshPeople() async {
    // TODO: backend removed - getAllPeople
    notifyListeners();
  }

  Future<Person?> createPersonProvider(String name) async {
    // TODO: backend removed - create person locally
    return null;
  }

  Future<void> setPeople() async {
    people = SharedPreferencesUtil().cachedPeople;
    notifyListeners();
  }

  Future<void> updatePersonProvider(Person person) async {
    // No-op: offline app
    notifyListeners();
  }

  Future<void> deletePersonSample(String personId, int sampleIndex) async {
    // No-op: offline app
    notifyListeners();
  }

  Future<bool> deletePersonProvider(String personId) async {
    // No-op: offline app
    notifyListeners();
    return true;
  }

  void playPause(int personIndex, int sampleIndex) {
    // No-op: offline app
    notifyListeners();
  }
}
