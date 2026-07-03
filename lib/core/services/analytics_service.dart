import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_service.dart';

/// Analytics boundary. Debug logger until Firebase Analytics is wired
/// (story 0.3/1.6); event names are stable from day one so funnels built in
/// the console keep working when the backend swaps in.
abstract interface class AnalyticsService {
  void logEvent(String name, [Map<String, Object?> params = const {}]);
}

/// Event name constants — the activation funnel from docs/01-product-plan.md.
abstract final class AnalyticsEvents {
  static const onboardingStep = 'onboarding_step'; // params: step
  static const homeCreated = 'home_created';
  static const firstAssetAdded = 'first_asset_added';
  static const firstReminderScheduled = 'first_reminder_scheduled';
  static const reminderFired = 'reminder_fired';
  static const reminderActioned = 'reminder_actioned';
  static const billMarkedPaid = 'bill_marked_paid';
  static const familyInviteSent = 'family_invite_sent';
}

class DebugAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    debugPrint('[analytics] $name ${params.isEmpty ? '' : params}');
  }
}

class NoopAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {}
}

final analyticsProvider = Provider<AnalyticsService>((ref) {
  final enabled = ref.watch(analyticsEnabledProvider).value ?? true;
  return enabled ? DebugAnalyticsService() : NoopAnalyticsService();
});
