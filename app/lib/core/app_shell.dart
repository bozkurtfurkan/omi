import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';

import 'package:omi/backend/preferences.dart';
import 'package:omi/mobile/mobile_app.dart';
// TODO: service removed - import 'package:omi/pages/settings/asana_settings_page.dart';
// TODO: service removed - import 'package:omi/pages/settings/clickup_settings_page.dart';
// TODO: page deleted - import 'package:omi/pages/settings/usage_page.dart';
// TODO: page deleted - import 'package:omi/pages/settings/wrapped_2025_page.dart';
import 'package:omi/providers/action_items_provider.dart';
import 'package:omi/providers/app_provider.dart';
import 'package:omi/providers/auth_provider.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:omi/providers/integration_provider.dart';
import 'package:omi/providers/message_provider.dart';
import 'package:omi/providers/people_provider.dart';
import 'package:omi/providers/task_integration_provider.dart';
import 'package:omi/providers/usage_provider.dart';
import 'package:omi/providers/user_provider.dart';
// TODO: service removed - import 'package:omi/services/asana_service.dart';
// TODO: service removed - import 'package:omi/services/clickup_service.dart';
// TODO: service removed - import 'package:omi/services/google_tasks_service.dart';
// TODO: service removed - import 'package:omi/services/notifications.dart';
// TODO: service removed - import 'package:omi/services/todoist_service.dart';
import 'package:omi/utils/alerts/app_snackbar.dart';
import 'package:omi/utils/l10n_extensions.dart';
import 'package:omi/utils/logger.dart';
import 'package:omi/utils/platform/platform_manager.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link (cold start — app launched by deep link)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      Logger.debug('onInitialAppLink: $initialUri');
      openAppLink(initialUri);
    }

    // Handle subsequent links (warm start — app already running)
    _linkSubscription = _appLinks.uriLinkStream.distinct().listen((uri) {
      Logger.debug('onAppLink: $uri');
      openAppLink(uri);
    });
  }

  void openAppLink(Uri uri) async {
    if (uri.pathSegments.isEmpty) {
      Logger.debug('No path segments in URI: $uri');
      return;
    }

    if (uri.pathSegments.first == 'wrapped') {
      if (mounted) {
        PlatformManager.instance.mixpanel.track('Wrapped Opened From DeepLink');
        // Wrapped2025Page deleted
      }
    } else if (uri.pathSegments.first == 'tasks' && uri.pathSegments.length > 1) {
      if (mounted) {
        final token = uri.pathSegments[1];
        PlatformManager.instance.mixpanel.track('Shared Tasks Opened From DeepLink', properties: {'token': token});
        _handleSharedTasksDeepLink(token);
      }
    } else if (uri.pathSegments.first == 'unlimited') {
      if (mounted) {
        PlatformManager.instance.mixpanel.track('Plans Opened From DeepLink');
        // UsagePage deleted
        Logger.debug('UsagePage deep link: page deleted');
      }
    } else if (uri.host == 'todoist' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'callback') {
      // TODO: service removed - Todoist OAuth callback removed
      Logger.debug('Todoist OAuth callback: service removed');
    } else if (uri.host == 'asana' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'callback') {
      // TODO: service removed - Asana OAuth callback removed
      Logger.debug('Asana OAuth callback: service removed');
    } else if (uri.host == 'google-tasks' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'callback') {
      // TODO: service removed - Google Tasks OAuth callback removed
      Logger.debug('Google Tasks OAuth callback: service removed');
    } else if (uri.host == 'clickup' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'callback') {
      // TODO: service removed - ClickUp OAuth callback removed
      Logger.debug('ClickUp OAuth callback: service removed');
    } else if (uri.host == 'google_calendar' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'callback') {
      await _handleOAuthCallback(uri, 'Google', 'Google Calendar', _handleGoogleCalendarCallback);
    } else {
      Logger.debug('Unknown link: $uri');
    }
  }

  Future<void> _handleOAuthCallback(
    Uri uri,
    String errorDisplayName,
    String oauthLogName,
    Future<void> Function() onSuccess,
  ) async {
    final error = uri.queryParameters['error'];
    if (error != null) {
      Logger.debug('$oauthLogName OAuth error: $error');
      AppSnackbar.showSnackbarError(context.l10n.failedToConnectServiceWithError(errorDisplayName, error));
      return;
    }

    final success = uri.queryParameters['success'];
    if (success == 'true') {
      Logger.debug('$oauthLogName OAuth successful (tokens in Firebase)');
      await onSuccess();
    } else {
      Logger.debug('$oauthLogName callback received but no success flag');
    }
  }

  Future<void> _handleSharedTasksDeepLink(String token) async {
    // AcceptSharedTasksSheet removed
  }

  Future<void> _handleGoogleCalendarCallback() async {
    if (!mounted) return;

    try {
      // Capture provider before async operation to avoid use_build_context_synchronously
      final integrationProvider = context.read<IntegrationProvider>();

      // IntegrationProvider.loadFromBackend() fetches all connection statuses
      // and syncs SharedPreferences for backward compatibility
      await integrationProvider.loadFromBackend();

      if (!mounted) return;
      Logger.debug('✓ Google authentication completed successfully');
      AppSnackbar.showSnackbar(context.l10n.successfullyConnectedGoogle);
    } catch (e) {
      Logger.debug('Error handling Google Calendar callback: $e');
      if (mounted) {
        AppSnackbar.showSnackbarError(context.l10n.failedToRefreshGoogleStatus);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeProviders();
      // Start deep link handling AFTER providers are ready,
      // so getInitialLink() doesn't race against cache loading (#4763)
      if (mounted) {
        initDeepLinks();
      }
    });
  }

  Future<void> _initializeProviders() async {
    if (!mounted) return;
    final signedIn = context.read<AuthenticationProvider>().isSignedIn();
    if (signedIn) {
      context.read<HomeProvider>().setupHasSpeakerProfile();
      context.read<HomeProvider>().setupUserPrimaryLanguage();
      context.read<UserProvider>().initialize();
      context.read<PeopleProvider>().initialize();
      try {
        // TODO: service removed - await PlatformManager.instance.intercom.loginIdentifiedUser(SharedPreferencesUtil().uid);
      } catch (e) {
        Logger.debug('Failed to login to Intercom: $e');
      }

      if (!mounted) return;
      context.read<MessageProvider>().setMessagesFromCache();
      context.read<AppProvider>().setAppsFromCache();
      context.read<MessageProvider>().refreshMessages();
      context.read<UsageProvider>().fetchSubscription();
      context.read<TaskIntegrationProvider>().loadFromBackend();

      // TODO: service removed - NotificationService.instance.saveNotificationToken();
    } else {
      if (!PlatformManager.instance.isAnalyticsSupported) {
        await PlatformManager.instance.intercom.loginUnidentifiedUser();
      }
      if (!mounted) return;
    }
    PlatformManager.instance.intercom.setUserAttributes();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MobileApp();
  }
}
