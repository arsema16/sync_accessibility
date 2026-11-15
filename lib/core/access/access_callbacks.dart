import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// What a single voice-input attempt produced.
enum VoiceInputStatus {
  /// Words were recognised and are ready to insert.
  recognized,

  /// Listening ended without hearing anything usable — the user may not have
  /// spoken within the window, or the engine could not match the speech.
  noSpeech,

  /// The device cannot provide speech input at all (no recogniser on the
  /// device, or the microphone permission was refused).
  unavailable,
}

/// Outcome of one [VoiceInputCallback] call.
class VoiceInputResult {
  const VoiceInputResult.recognized(this.text)
      : status = VoiceInputStatus.recognized;
  const VoiceInputResult.noSpeech()
      : text = '',
        status = VoiceInputStatus.noSpeech;
  const VoiceInputResult.unavailable()
      : text = '',
        status = VoiceInputStatus.unavailable;

  /// The recognised words — empty unless [status] is
  /// [VoiceInputStatus.recognized].
  final String text;
  final VoiceInputStatus status;
}

/// Invoked when the user taps the mic button on a voice-capable form step.
typedef VoiceInputCallback = Future<VoiceInputResult> Function();

/// Invoked when the app reads text aloud.
typedef ReadAloudCallback = void Function(String text);

/// Returns a [VoiceInputCallback] backed by the device speech recogniser.
///
/// The [SpeechToText] instance is created once and reused across taps.
/// initialize() is called once; subsequent taps skip straight to listening.
///
/// ## Why listening restarts itself
///
/// The platform recogniser kills a session after roughly 3 seconds if it has
/// not locked onto speech (`error_speech_timeout` / `error_no_match`), which
/// fails anyone who taps the mic and takes a beat to start talking. Rather
/// than ending there, every session that produced nothing is restarted — up
/// to [maxRetries] more times — so a single tap gives one continuous
/// listening window of roughly 15–20 seconds. The form screen keeps showing
/// "Listening…" throughout, because the returned future only settles when a
/// session produces words, the retry budget runs out, or a non-retryable
/// error arrives.
///
/// Every failure mode is logged with a `[SYNC voice]` prefix so
/// `adb logcat -s flutter` shows whether the cause was the recogniser
/// service, the microphone permission, or speech the engine never matched.
VoiceInputCallback makeVoiceInputCallback() {
  /// Extra listening windows after the first, per tap. Five retries at ~3.2s
  /// per empty session ≈ 19s of continuous listening before giving up.
  const maxRetries = 5;

  final stt = SpeechToText();
  var initialized = false;
  Completer<VoiceInputResult>? activeCompleter;
  var lastWords = '';
  var retriesLeft = 0;
  var lastSessionEndMs = 0;

  /// Settles the in-flight tap, if there is one.
  void finishWith(VoiceInputResult result) {
    final completer = activeCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  // Declared late so sessionEnded can restart listening no matter which
  // closure runs first; it is assigned below before any event can arrive.
  late Future<void> Function() startListening;

  /// A listening session just ended: return what it heard, restart the
  /// recogniser while the retry budget lasts, or give up.
  void sessionEnded(String trigger) {
    final completer = activeCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    // One dead session emits several close events in quick succession
    // (notListening, done, then an error ~180ms later); only the first may
    // restart, or the late events would stack extra sessions.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastSessionEndMs < 800) {
      debugPrint('[SYNC voice] ignoring late end event ($trigger)');
      return;
    }
    if (lastWords.isNotEmpty) {
      finishWith(VoiceInputResult.recognized(lastWords));
      return;
    }
    if (retriesLeft <= 0) {
      debugPrint('[SYNC voice] giving up after retries ($trigger)');
      finishWith(const VoiceInputResult.noSpeech());
      return;
    }
    retriesLeft--;
    lastSessionEndMs = nowMs;
    debugPrint(
      '[SYNC voice] no speech yet — restarting ($retriesLeft retries left)',
    );
    unawaited(startListening());
  }

  startListening = () async {
    lastWords = '';
    stt.statusListener = (status) {
      debugPrint('[SYNC voice] status: $status');
      if (status != 'listening') {
        sessionEnded('status:$status');
      }
    };
    await stt.listen(
      onResult: (result) {
        // Never let an empty final result erase partial words we already
        // have; only a non-empty transcript replaces them.
        if (result.recognizedWords.isNotEmpty) {
          lastWords = result.recognizedWords;
        }
        if (result.finalResult) {
          if (lastWords.isNotEmpty) {
            finishWith(VoiceInputResult.recognized(lastWords));
          } else {
            sessionEnded('final result was empty');
          }
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
  };

  return () async {
    try {
      // Initialize only once — re-initializing on Android causes failures.
      if (!initialized) {
        initialized = await stt.initialize(
          // Plugin-side logging, visible in logcat only.
          debugLogging: true,
          onError: (error) {
            // Errors arrive here both during init and mid-listen.
            debugPrint('[SYNC voice] error: $error');
            final msg = error.errorMsg;
            if (msg == 'error_speech_timeout' || msg == 'error_no_match') {
              // The classic "tapped, then started speaking" miss — retry.
              sessionEnded('error:$msg');
            } else if (lastWords.isNotEmpty) {
              finishWith(VoiceInputResult.recognized(lastWords));
            } else {
              // Client/permission/language failures are not retryable.
              finishWith(const VoiceInputResult.unavailable());
            }
          },
          onStatus: (status) => debugPrint('[SYNC voice] status: $status'),
        );
        if (!initialized) {
          // Most often: the mic permission was denied, or the device has no
          // speech recognition service enabled.
          final hasMic = await stt.hasPermission;
          debugPrint(
            '[SYNC voice] initialize failed — mic permission: $hasMic',
          );
          return const VoiceInputResult.unavailable();
        }
      }

      // Stop any previous session before starting a new one.
      if (stt.isListening) {
        await stt.stop();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      retriesLeft = maxRetries;
      lastSessionEndMs = 0;
      final completer = Completer<VoiceInputResult>();
      activeCompleter = completer;

      await startListening();

      // Overall safety net: retryable sessions die on their own after ~3s,
      // but a session that never ends must not hang the form forever.
      return await completer.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          debugPrint('[SYNC voice] listen timed out');
          final result = lastWords.isNotEmpty
              ? VoiceInputResult.recognized(lastWords)
              : const VoiceInputResult.noSpeech();
          // Settle first so the end events triggered by stop() below are
          // ignored instead of starting another retry.
          finishWith(result);
          unawaited(stt.stop());
          return result;
        },
      );
    } catch (error) {
      // PlatformException 'recognizerNotAvailable' lands here when the device
      // exposes no speech service (common on emulators without Google apps).
      debugPrint('[SYNC voice] failed: $error');
      return lastWords.isNotEmpty
          ? VoiceInputResult.recognized(lastWords)
          : const VoiceInputResult.unavailable();
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
