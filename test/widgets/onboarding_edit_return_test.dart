import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/constants/route_names.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/core/router/app_router.dart';
import 'package:sync_accessibility/features/onboarding/contact_screen.dart';
import 'package:sync_accessibility/features/onboarding/profile_review_screen.dart';

// Regression test for the review finding "Edit links re-walk the downstream
// flow". Before the fix, Profile Review's Edit used `goNamed`, which discarded
// the review screen and forced the user to re-complete the downstream flow.
// After the fix, Edit pushes the section in edit mode and completing it pops
// straight back to review. This test would have failed on the old code because
// completing the contact edit would have landed on the identity screen, not the
// profile review screen.
void main() {
  testWidgets('editing a section from profile review returns to review',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: AppRoutes.profileReview,
      routes: appRouteList,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfileReviewScreen), findsOneWidget);

    // Open the Name section for editing.
    final nameCard = find.ancestor(
      of: find.text(AppStrings.sectionName),
      matching: find.byType(Card),
    );
    final editInName = find.descendant(
      of: nameCard,
      matching: find.text(AppStrings.edit),
    );
    await tester.ensureVisible(editInName);
    await tester.pumpAndSettle();
    await tester.tap(editInName);
    await tester.pumpAndSettle();

    // The contact screen is pushed on top of review (it does not replace it).
    expect(find.byType(ContactScreen), findsOneWidget);

    // Step 1 of 3 — full name.
    await tester.enterText(find.byType(TextField), 'Updated Name');
    final nextButton = find.widgetWithText(FilledButton, AppStrings.next);
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Step 2 of 3 — phone number.
    await tester.enterText(find.byType(TextField), '0987654321');
    final nextButton2 = find.widgetWithText(FilledButton, AppStrings.next);
    await tester.ensureVisible(nextButton2);
    await tester.tap(nextButton2);
    await tester.pumpAndSettle();

    // Step 3 of 3 — email is optional; finish the flow.
    final continueButton =
        find.widgetWithText(FilledButton, AppStrings.continueLabel);
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // The edit returned to profile review with the updated value, instead of
    // advancing into the identity / skills / support screens.
    expect(find.byType(ContactScreen), findsNothing);
    expect(find.byType(ProfileReviewScreen), findsOneWidget);
    expect(find.text('Updated Name'), findsOneWidget);
  });
}
