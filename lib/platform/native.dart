import 'package:flutter/services.dart';
import '../domain/models.dart';
import '../config.dart';

abstract class WorkroomPlatform {
  Future<ClockSample> clock();
  Future<void> alarm(int remainingMs);
  Future<void> cancelAlarm();
}

class NativePlatform implements WorkroomPlatform {
  static const channel = MethodChannel('app.workroom/native');
  Future<void> syncLanguage(String language) async {
    try {
      await channel.invokeMethod('setLanguage', {'language': language});
    } on MissingPluginException {
      // Widget tests and platforms without the Android notification bridge.
    }
  }

  @override
  Future<ClockSample> clock() async {
    final v = await channel.invokeMapMethod<String, dynamic>('clock');
    return ClockSample(
      v!['elapsedMs'] as int,
      v['boot'] as String,
      v['utcMs'] as int,
    );
  }

  @override
  Future<void> alarm(int remainingMs) async {
    await channel.invokeMethod('scheduleAlarm', {'remainingMs': remainingMs});
  }

  @override
  Future<void> cancelAlarm() async {
    await channel.invokeMethod('cancelAlarm');
  }

  Future<bool> notifications() async =>
      await channel.invokeMethod<bool>('requestNotifications') ?? false;
  Future<void> export(String value) async {
    await channel.invokeMethod('export', {'content': value});
  }

  Future<Map<String, dynamic>> wallet(
    String method, [
    Map<String, dynamic> args = const {},
  ]) async {
    final result = await channel.invokeMapMethod<String, dynamic>(method, {
      'identityUri': AppConfig.identityUri,
      'identityName': AppConfig.name,
      ...args,
    });
    return Map<String, dynamic>.from(result ?? {});
  }
}
