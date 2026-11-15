import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/access/access_callbacks.dart';
import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/shared/widgets/form_step.dart';
import 'package:sync_accessibility/shared/widgets/question_screen.dart';

void main() {
  Future<SharedPreferences> pump(
    WidgetTester tester, {
    required List<FormStep> steps,
    required Map<String, Object> initialAccess,
    ReadAloudCallback? readAloud,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (initialAccess.isNotEmpty)
        'sync.access_passport': jsonEncode(initialAccess),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          if (readAloud != null)
            readAloudProvider.overrideWithValue(readAloud),
        ],
        child: MaterialApp(
          home: QuestionScreen(
            steps: steps,
            onComplete: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  const normalStep = FormStep(
    id: 'fullName',
    title: AppStrings.fullNameQuestion,
    hint: AppStrings.fullNameHint,
    simpleTitle: AppStrings.fullNameQuestionSimple,
    simpleHint: AppStrings.fullNameHintSimple,
    inputType: FormInputType.text,
  );

  testWidgets('shows the plain wording by default', (tester) async {
    await pump(tester, steps: const <FormStep>[normalStep], initialAccess: {});

    expect(find.text(AppStrings.fullNameQuestion), findsWidgets);
    expect(find.text(AppStrings.fullNameQuestionSimple), findsNothing);
  });

  testWidgets('shows the simpler wording when the preference is on',
      (tester) async {
    await pump(
      tester,
      steps: const <FormStep>[normalStep],
      initialAccess: <String, Object>{'simplerWording': true},
    );

    expect(find.text(AppStrings.fullNameQuestionSimple), findsWidgets);
    expect(find.text(AppStrings.fullNameQuestion), findsNothing);
    // The hint swaps too (shown as helper text and as the field hint).
    expect(find.text(AppStrings.fullNameHintSimple), findsWidgets);
  });

  testWidgets('read-aloud speaks the simpler title when enabled',
      (tester) async {
    final spoken = <String>[];
    await pump(
      tester,
      steps: const <FormStep>[normalStep],
      initialAccess: <String, Object>{
        'simplerWording': true,
        'readAloud': true,
      },
      readAloud: (text) => spoken.add(text),
    );

    expect(spoken, contains(AppStrings.fullNameQuestionSimple));
    expect(spoken, isNot(contains(AppStrings.fullNameQuestion)));
  });

  testWidgets('text steps offer a voice button next to the typed field',
      (tester) async {
    await pump(tester, steps: const <FormStep>[normalStep], initialAccess: {});

    // The typed answer is always available...
    expect(find.byType(TextField), findsOneWidget);
    // ...and so is speaking it.
    expect(find.widgetWithText(OutlinedButton, AppStrings.speakInstead),
        findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });
}
