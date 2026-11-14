import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/shared/widgets/form_step.dart';
import 'package:sync_accessibility/shared/widgets/question_screen.dart';

void main() {
  testWidgets('QuestionScreen renders a single step with progress and a text input',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    Map<String, Object>? captured;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: QuestionScreen(
            steps: const <FormStep>[
              FormStep(
                id: 'fullName',
                title: AppStrings.fullNameQuestion,
                hint: AppStrings.fullNameHint,
                inputType: FormInputType.text,
              ),
            ],
            onComplete: (answers) => captured = answers,
          ),
        ),
      ),
    );

    // Progress is shown visually and announced.
    expect(find.text(AppStrings.stepProgressLabel(1, 1)), findsOneWidget);
    // A single text input is rendered for a text step.
    expect(find.byType(TextField), findsOneWidget);
    // On the last step the advance button uses the final-step label.
    expect(find.text(AppStrings.continueLabel), findsOneWidget);
    expect(find.text(AppStrings.next), findsNothing);
    // The "Back" control is hidden on the first step.
    expect(find.text(AppStrings.back), findsNothing);

    expect(captured, isNull);
  });
}
