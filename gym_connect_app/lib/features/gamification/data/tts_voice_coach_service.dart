import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Intelligent voice coach utilizing Text-To-Speech with audio debouncing.
class TtsVoiceCoachService {
  final FlutterTts _tts;
  final Future<dynamic> Function(String)? customSpeak;
  double ttsCooldownSeconds;
  DateTime? _lastSpokenAt;
  String? _lastPhrase;
  bool _isInitialized = false;

  TtsVoiceCoachService({
    FlutterTts? tts,
    this.customSpeak,
    this.ttsCooldownSeconds = 3.2,
  }) : _tts = tts ?? FlutterTts();

  bool get isInitialized => _isInitialized;
  DateTime? get lastSpokenAt => _lastSpokenAt;
  String? get lastPhrase => _lastPhrase;

  void setCooldownSeconds(double seconds) {
    ttsCooldownSeconds = seconds;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.52);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isInitialized = true;
    } on MissingPluginException {
      _isInitialized = true;
    } catch (e) {
      debugPrint('TtsVoiceCoachService initialization error: $e');
    }
  }

  /// Speaks [phrase] with debouncing to prevent audio spam.
  Future<bool> speak(
    String phrase, {
    Duration? cooldown,
  }) async {
    final now = DateTime.now();
    final effectiveCooldown = cooldown ?? Duration(milliseconds: (ttsCooldownSeconds * 1000).toInt());

    // Debounce check: prevent speaking too frequently
    if (_lastSpokenAt != null) {
      final elapsed = now.difference(_lastSpokenAt!);
      final requiredCooldown = (_lastPhrase == phrase)
          ? effectiveCooldown + const Duration(milliseconds: 1000)
          : effectiveCooldown;
      if (elapsed < requiredCooldown) {
        return false;
      }
    }

    _lastSpokenAt = now;
    _lastPhrase = phrase;

    try {
      final handler = customSpeak;
      if (handler != null) {
        await handler(phrase);
      } else {
        await _tts.speak(phrase);
      }
      return true;
    } on MissingPluginException {
      // In headless unit test environments, native method channels are absent.
      return true;
    } catch (e) {
      debugPrint('TtsVoiceCoachService speak error: $e');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void resetDebounce() {
    _lastSpokenAt = null;
    _lastPhrase = null;
  }

  void dispose() {
    stop();
  }
}
