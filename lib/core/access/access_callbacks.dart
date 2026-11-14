import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Invoked when the user taps the mic button on a voice-capable form step.
///
/// Returns the recognised text, or an empty string if nothing was recognised.
typedef VoiceInputCallback = Future<String> Function();

/// Invoked when the app reads text aloud.
typedef ReadAloudCallback = void Function(String text);

/// Returns a [VoiceInputCallback] backed by the device speech recogniser.
/// Returns empty string if recognition is unavailable or nothing is heard.
VoiceInputCallback makeVoiceInputCallback() {
  final stt = SpeechToText();
  return () async {
    try {
      final available = await stt.initialize();
      if (!available) return '';
      final completer = Completer<String>();
      await stt.listen(
        onResult: (result) {
          if (result.finalResult) {
            completer.complete(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          cancelOnError: true,
        ),
      );
      return await completer.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () => '',
      );
    } catch (_) {
      return '';
    }
  };
}

/// Returns a [ReadAloudCallback] backed by [FlutterTts].
ReadAloudCallback makeReadAloudCallback() {
  final tts = FlutterTts();
  tts.setLanguage('en-US');
  return (String text) {
    tts.speak(text);
  };
}
