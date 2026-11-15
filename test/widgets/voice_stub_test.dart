import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/access/access_callbacks.dart';
import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/shared/widgets/form_step.dart';
import 'package:sync_accessibility/shared/widgets/question_screen.dart';

// Covers the voice input stub behaviour on the voice form step.
// The injected VoiceInputCallback reports "unavailable"; the form engine
// must surface the typed-fallback hint. The typed TextField is hidden until
// the user taps "Type instead" (design change: mic-first, type on demand).
Future<void> _pumpVoiceStep(
  WidgetTester tester, {
  required VoiceInputCallback voice,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        voiceInputProvider.overrideWithValue(voice),
      ],
      child: MaterialApp(
        home: QuestionScreen(
          steps: const <FormStep>[
            FormStep(
              id: 'occupation',
              title: AppStrings.occupationQuestion,
              hint: AppStrings.occupationHint,
              inputType: FormInputType.voice,
            ),
          ],
          onComplete: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('voice stub returns empty and shows the typed-fallback hint',
      (tester) async {
    await _pumpVoiceStep(
      tester,
      voice: () async => const VoiceInputResult.unavailable(),
    );

    // TextField is hidden by default; "Type instead" reveals it.
    expect(find.byType(TextField), findsNothing);

    // Tap "Type instead" — the TextField should appear.
    await tester.tap(find.text('Type instead'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    // Mic icon is present (inside SyncVoiceMicButton via GestureDetector).
    expect(find.byIcon(Icons.mic_none), findsOneWidget);

    // Tap the mic button (GestureDetector wraps the mic button).
    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pumpAndSettle();

    // The stub reported "unavailable", so the not-ready hint is shown.
    expect(find.text(AppStrings.voiceUnavailable), findsOneWidget);
  });

  testWidgets(
      'a session that hears nothing asks the user to start speaking, '
      'instead of claiming voice input is not ready', (tester) async {
    await _pumpVoiceStep(
      tester,
      voice: () async => const VoiceInputResult.noSpeech(),
    );

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.voiceNoSpeech), findsOneWidget);
    expect(find.text(AppStrings.voiceUnavailable), findsNothing);
  });
}
