// Capabilities that are stubbed for now and wired by another teammate.
//
// Both are injected through riverpod providers (see
// `lib/core/providers/app_providers.dart`) so they can be overridden the same
// way as the services.

/// Invoked when the user taps the mic button on a voice-capable form step.
///
/// Returns the recognised text, or an empty string if nothing was recognised.
/// The stub returns an empty string so typed fallback always remains available.
typedef VoiceInputCallback = Future<String> Function();

/// Invoked when the user asks SYNC to read text aloud. The stub is a no-op.
typedef ReadAloudCallback = void Function(String text);

// TODO(bethel): wire the real speech-recognition API behind voiceInputStub.
Future<String> voiceInputStub() async => '';

// TODO(bethel): wire the real text-to-speech API behind readAloudStub.
void readAloudStub(String _) {}
