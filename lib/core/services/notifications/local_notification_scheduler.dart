import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../features/reminders/reminder_policies.dart';
import 'notification_scheduler.dart';

/// Android/iOS implementation over flutter_local_notifications.
///
/// Notification ids: a reminder's chain occupies a contiguous id block
/// derived from its uuid hash, so replacing/cancelling a chain never touches
/// other reminders' notifications.
class LocalNotificationScheduler implements NotificationScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _available = false;

  static const _channel = AndroidNotificationDetails(
    'homevault_reminders',
    'Home reminders',
    channelDescription: 'Bills, warranties, and service reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    // Notification scheduling is best-effort relative to DB state: a missing
    // platform (tests, unsupported OS) must never break engine mutations.
    try {
      await _initializePlugin();
    } catch (_) {
      _available = false;
    }
    _initialized = true;
  }

  Future<void> _initializePlugin() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    // Exact alarms make due-day reminders punctual; inexact is the fallback.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _available = true;
  }

  @override
  Future<bool> requestPermissions() async {
    await initialize();
    if (!_available) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      return granted ?? await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  @override
  Future<bool> areEnabled() async {
    await initialize();
    if (!_available) return true; // no platform → nothing to warn about
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true; // iOS: checked at request time
  }

  int _baseId(String reminderId) =>
      (reminderId.hashCode & 0x7fffffff) % 2000000 * maxScheduledPerReminder;

  @override
  Future<void> scheduleChain({
    required String reminderId,
    required String title,
    required String body,
    required List<DateTime> times,
  }) async {
    await initialize();
    if (!_available) return;
    await cancelChain(reminderId);
    final base = _baseId(reminderId);
    for (var i = 0; i < times.length && i < maxScheduledPerReminder; i++) {
      await _plugin.zonedSchedule(
        id: base + i,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(times[i], tz.local),
        notificationDetails: const NotificationDetails(
            android: _channel, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminderId,
      );
    }
  }

  @override
  Future<void> cancelChain(String reminderId) async {
    await initialize();
    if (!_available) return;
    final base = _baseId(reminderId);
    for (var i = 0; i < maxScheduledPerReminder; i++) {
      await _plugin.cancel(id: base + i);
    }
  }
}
