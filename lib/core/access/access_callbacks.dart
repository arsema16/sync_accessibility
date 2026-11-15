import 'dart:async';

import 'package:flutter/foundation.dart';
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
///
/// Failures always resolve to an empty string (the form engine then shows
/// the typed-fallback hint), but every failure mode is logged with a
/// `[SYNC voice]` prefix so `adb logcat -s flutter` shows whether the cause
/// was a missing microphone permission, no recogniser on the device, or a
/// recognition error mid-listen.
VoiceInputCallback makeVoiceInputCallback() {
  final stt = SpeechToText();
  bool initialized = false;
  Completer<String>? activeCompleter;
  var lastWords = '';

  /// Completes the in-flight listen, if there is one.
  void finishWith(String words) {
    final completer = activeCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(words);
    }
  }

  return () async {
    try {
      // Initialize only once — re-initializing on Android causes failures.
      if (!initialized) {
        initialized = await stt.initialize(
          // Plugin-side logging, visible in logcat only.
          debugLogging: true,
          onError: (error) {
            // Errors arrive here both during init and mid-listen; finish the
            // current answer instead of waiting out the full timeout.
            debugPrint('[SYNC voice] error: $error');
            finishWith(lastWords);
          },
          onStatus: (status) {
            debugPrint('[SYNC voice] status: $status');
            if (status == 'done' || status == 'notListening') {
              finishWith(lastWords);
            }
          },
        );
        if (!initialized) {
          // Most often: the mic permission was denied, or the device has no
          // speech recognition service enabled.
          final hasMic = await stt.hasPermission;
          debugPrint(
            '[SYNC voice] initialize failed — mic permission: $hasMic',
          );
          return '';
        }
      }

      // Stop any previous session before starting a new one.
      if (stt.isListening) {
        await stt.stop();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      lastWords = '';
      final completer = Completer<String>();
      activeCompleter = completer;

      // Registered before listen() so a very fast session can't finish
      // before we start watching for the end status.
      stt.statusListener = (status) {
        if (status == 'done' || status == 'notListening') {
          finishWith(lastWords);
        }
      };

      await stt.listen(
        onResult: (result) {
          // Track partial results so we always have something to return.
          lastWords = result.recognizedWords;
          if (result.finalResult) {
            finishWith(lastWords);
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
      return await completer.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          debugPrint('[SYNC voice] listen timed out');
          stt.stop();
          return lastWords;
        },
      );
    } catch (error) {
      // PlatformException 'recognizerNotAvailable' lands here when the device
      // exposes no speech service (common on emulators without Google apps).
      debugPrint('[SYNC voice] failed: $error');
      return '';
    } finally {
      activeCompleter = null;
    }
  };
}

/// Returns a [ReadAloudCallback] backed by [FlutterTts].
///
/// Each call cuts off whatever is still playing first, so moving quickly
/// between screens announces the screen you landed on instead of queueing a
/// backlog of headings behind it.
ReadAloudCallback makeReadAloudCallback() {
  final tts = FlutterTts();
  tts.setLanguage('en-US');

  Future<void> say(String text) async {
    try {
      await tts.stop();
    } catch (_) {
      // The engine may not be ready yet; speak() below starts it.
    }
    try {
      await tts.speak(text);
    } catch (error) {
      // A missing or blocked TTS engine must never break the screen.
      debugPrint('[SYNC voice] read-aloud failed: $error');
    }
  }

  return say;
}
