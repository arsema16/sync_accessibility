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
///
/// The [SpeechToText] instance is created once and reused across taps.
/// initialize() is called once; subsequent taps skip straight to listen().
VoiceInputCallback makeVoiceInputCallback() {
  final stt = SpeechToText();
  bool initialized = false;

  return () async {
    try {
      // Initialize only once — re-initializing on Android causes failures.
      if (!initialized) {
        initialized = await stt.initialize(
          onError: (_) {},
          onStatus: (_) {},
        );
      }
      if (!initialized) return '';

      // Stop any previous session before starting a new one.
      if (stt.isListening) {
        await stt.stop();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      final completer = Completer<String>();
      String lastWords = '';

      await stt.listen(
        onResult: (result) {
          // Track partial results so we always have something to return.
          lastWords = result.recognizedWords;
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(result.recognizedWords);
          }
        },
        // partialResults must be true on Android to receive any callbacks.
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: false,
          partialResults: true,
        ),
      );

      // Wait for a final result. If the recogniser stops without firing
      // finalResult (e.g. silence timeout), complete with the last partial.
      stt.statusListener = (status) {
        if (status == 'done' || status == 'notListening') {
          if (!completer.isCompleted) {
            completer.complete(lastWords);
          }
        }
      };

      return await completer.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          stt.stop();
          return lastWords;
        },
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
