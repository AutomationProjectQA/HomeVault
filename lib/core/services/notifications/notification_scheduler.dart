import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_notification_scheduler.dart';

/// Schedules OS notifications for a reminder's chain. Abstracted so the
/// engine and tests never touch platform plugins directly.
abstract interface class NotificationScheduler {
  Future<void> initialize();

  /// Explicitly (re)requests notification + exact-alarm permissions.
  /// Returns whether notifications are permitted afterwards.
  Future<bool> requestPermissions();

  /// Whether the OS will currently deliver our notifications.
  Future<bool> areEnabled();

  /// Replaces all scheduled notifications for [reminderId] with [times].
  Future<void> scheduleChain({
    required String reminderId,
    required String title,
    required String body,
    required List<DateTime> times,
  });

  Future<void> cancelChain(String reminderId);
}

/// Web/desktop and tests: engine logic runs, no OS notifications.
class NoopNotificationScheduler implements NotificationScheduler {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> areEnabled() async => true; // nothing to enable here

  @override
  Future<void> scheduleChain({
    required String reminderId,
    required String title,
    required String body,
    required List<DateTime> times,
  }) async {}

  @override
  Future<void> cancelChain(String reminderId) async {}
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  if (kIsWeb ||
      !(defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return NoopNotificationScheduler();
  }
  return LocalNotificationScheduler();
});
