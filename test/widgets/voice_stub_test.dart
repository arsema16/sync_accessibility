import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/shared/widgets/form_step.dart';
import 'package:sync_accessibility/shared/widgets/question_screen.dart';

// Covers the review finding "Behavioral paths untested" for the voice input
// stub. The injected VoiceInputCallback stub returns an empty string; the form
// engine must surface the typed-fallback hint and always keep the typed field.
void main() {
  testWidgets('voice stub returns empty and shows the typed-fallback hint',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    // Override voiceInputProvider with a stub that always returns empty string.
    Future<String> emptyVoice() async => '';

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          voiceInputProvider.overrideWithValue(emptyVoice),
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

    // Typed fallback is always present, regardless of the voice slot.
    expect(find.byType(TextField), findsOneWidget);

    final micButton = find.ancestor(
      of: find.byIcon(Icons.mic_none),
      matching: find.byType(FilledButton),
    );
    expect(micButton, findsOneWidget);

    await tester.tap(micButton);
    await tester.pumpAndSettle();

    // The stub returned empty, so the plain-language fallback hint is shown.
    expect(find.text(AppStrings.voiceUnavailable), findsOneWidget);
  });
}
