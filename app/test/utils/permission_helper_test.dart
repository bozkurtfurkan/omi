import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:omi/utils/permission_helper.dart';

void main() {
  test('requiredPermissions includes microphone', () {
    expect(PermissionHelper.requiredPermissions, contains(Permission.microphone));
  });

  test('requiredPermissions is not empty', () {
    expect(PermissionHelper.requiredPermissions, isNotEmpty);
  });
}
