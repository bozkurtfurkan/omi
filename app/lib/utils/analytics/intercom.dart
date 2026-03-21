/// Stubbed IntercomManager - no Intercom for offline app.
class IntercomManager {
  static final IntercomManager _instance = IntercomManager._internal();
  factory IntercomManager() => _instance;
  IntercomManager._internal();

  static IntercomManager get instance => _instance;

  IntercomManager get intercom => _instance;

  static Future<void> init() async {}
  Future<void> initIntercom() async {}
  Future<void> displayMessenger() async {}
  Future<void> displayHelpCenter() async {}
  Future<void> updateUser({String? email, String? name, String? userId}) async {}
  Future<void> logout() async {}
  Future<void> loginUnidentifiedUser() async {}
  Future<void> loginIdentifiedUser(String userId) async {}
  Future<void> setUserAttributes() async {}
  void updateCustomAttributes(Map<String, dynamic> attributes) {}
  void logEvent(String eventName, {Map<String, dynamic>? metaData}) {}
  void displayChargingArticle() {}
  void displayFirmwareUpdateArticle() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
