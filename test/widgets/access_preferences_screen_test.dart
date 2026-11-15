import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/features/onboarding/access_preferences_screen.dart';
import 'package:sync_accessibility/shared/widgets/sync_option_card.dart';

void main() {
  testWidgets('tapping a preference card selects it', (tester) async {
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

    final labelFinder = find.text('Large Text');
    expect(labelFinder, findsOneWidget);

    final cardFinder = find.ancestor(
      of: labelFinder,
      matching: find.byType(SyncOptionCard),
    );
    expect(cardFinder, findsOneWidget);

    expect(tester.widget<SyncOptionCard>(cardFinder).selected, isFalse);

    // The card may sit below the fold in the scroll view; bring it on-screen.
    await tester.ensureVisible(cardFinder);
    await tester.pumpAndSettle();

    await tester.tap(cardFinder);
    await tester.pump();

    expect(tester.widget<SyncOptionCard>(cardFinder).selected, isTrue);
  });
}
