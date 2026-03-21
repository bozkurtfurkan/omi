import 'package:flutter/material.dart';

import 'package:omi/providers/base_provider.dart';

/// Stubbed out - no auth needed for fully offline app.
class AuthenticationProvider extends BaseProvider {
  bool _isSignedIn = false;
  bool isSigningIn = false;

  bool isSignedIn() => _isSignedIn;

  Future<void> signOut() async {
    // No-op: offline app
  }

  Future<bool> onGoogleSignIn() async {
    // No-op: offline app
    return false;
  }

  Future<bool> onAppleSignIn() async {
    // No-op: offline app
    return false;
  }

  void openPrivacyPolicy() {
    // No-op: offline app
  }

  void openTermsOfService() {
    // No-op: offline app
  }
}
