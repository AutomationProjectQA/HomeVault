import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences persisted on-device (not synced — they're per-device
/// choices like app lock, which one family member may want and another not).
abstract final class PrefKeys {
  static const appLockEnabled = 'app_lock_enabled';
  static const analyticsEnabled = 'analytics_enabled';
}

class AppLockEnabled extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefKeys.appLockEnabled) ?? false;
  }

  Future<void> set(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.appLockEnabled, value);
    state = AsyncData(value);
  }
}

final appLockEnabledProvider =
    AsyncNotifierProvider<AppLockEnabled, bool>(AppLockEnabled.new);

class AnalyticsEnabled extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefKeys.analyticsEnabled) ?? true;
  }

  Future<void> set(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.analyticsEnabled, value);
    state = AsyncData(value);
  }
}

final analyticsEnabledProvider =
    AsyncNotifierProvider<AnalyticsEnabled, bool>(AnalyticsEnabled.new);
