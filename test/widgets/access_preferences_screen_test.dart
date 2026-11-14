import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/features/onboarding/access_preferences_screen.dart';

void main() {
  testWidgets('tapping a preference chip selects it', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: AccessPreferencesScreen()),
      ),
    );

    final labelFinder = find.text(AppStrings.largerText);
    expect(labelFinder, findsOneWidget);

    final chipFinder = find.ancestor(of: labelFinder, matching: find.byType(FilterChip));
    expect(chipFinder, findsOneWidget);

    expect(tester.widget<FilterChip>(chipFinder).selected, isFalse);

    // The chip may sit below the fold in the scroll view; bring it on-screen.
    await tester.ensureVisible(chipFinder);
    await tester.pumpAndSettle();

    await tester.tap(chipFinder);
    await tester.pump();

    expect(tester.widget<FilterChip>(chipFinder).selected, isTrue);
  });
}
