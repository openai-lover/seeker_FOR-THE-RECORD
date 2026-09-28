import 'dart:convert';
import 'package:flutter/services.dart';

/// Only the Android bridge runs inference. This service never calls a server.
class ReflectionAssistant {
  const ReflectionAssistant();
  static const channel = MethodChannel('app.workroom/reflection');
  static const model =
      'multilingual-e5-small Q8 · semantic-v2 · llama.cpp 0.5.0';
  static const modelBytes = 132439008;

  Future<Map<String, dynamic>> status() async =>
      Map<String, dynamic>.from(await channel.invokeMapMethod('status') ?? {});
  Future<void> download() => channel.invokeMethod('download');
  Future<void> cancel() => channel.invokeMethod('cancel');
  Future<void> remove() => channel.invokeMethod('remove');

  static String contextFor(String reason, String plan, String review) {
    // Bounded input fits the small on-device model, even with Korean tokens.
    String clip(String value) =>
        String.fromCharCodes(value.trim().runes.take(140));
    return jsonEncode({
      'reason': clip(reason),
      'plan': clip(plan),
      'reflection': clip(review),
    });
  }

  Future<Map<String, dynamic>> suggest(String context) async {
    final response = await channel.invokeMapMethod<String, dynamic>('suggest', {
      'context': context,
    });
    final id = response?['questionId'];
    if (id is! int || id < 1 || id > 5) {
      throw PlatformException(code: 'invalid-answer');
    }
    final alternative = response?['alternativeId'];
    final uncertain = response?['uncertain'] == true;
    if (uncertain &&
        (alternative is! int ||
            alternative < 1 ||
            alternative > 5 ||
            alternative == id)) {
      throw PlatformException(code: 'invalid-answer');
    }
    return {
      'questionId': id,
      'source': 'ai',
      'model': model,
      'generatedAt': DateTime.now().millisecondsSinceEpoch,
      'durationMs': response?['durationMs'],
      'cold': response?['cold'],
      if (uncertain) 'candidates': [id, alternative],
      'context': context,
    };
  }
}
