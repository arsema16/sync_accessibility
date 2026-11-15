import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/constants/app_strings.dart';
import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/features/jobs/jobs_screen.dart';

// Home-screen layout contract:
//   - the greeting follows the time of day (morning/afternoon/evening)
//   - the whole screen — header, search, tip, filters, job cards — is one
//     CustomScrollView, so the cards scroll from the very top
//   - the search bar sits above the tip card with a plain search hint
//   - every category chip label stays fully visible (no clipped text)
void main() {
  group('JobsScreen.greetingFor', () {
    test('is morning before noon', () {
      expect(JobsScreen.greetingFor(DateTime(2026, 1, 1, 0)), 'Good morning!');
      expect(JobsScreen.greetingFor(DateTime(2026, 1, 1, 11)), 'Good morning!');
    });

    test('is afternoon from noon until 17:00', () {
      expect(
        JobsScreen.greetingFor(DateTime(2026, 1, 1, 12)),
        'Good afternoon!',
      );
      expect(
        JobsScreen.greetingFor(DateTime(2026, 1, 1, 16)),
        'Good afternoon!',
      );
    });

    test('is evening from 17:00', () {
      expect(JobsScreen.greetingFor(DateTime(2026, 1, 1, 17)), 'Good evening!');
      expect(JobsScreen.greetingFor(DateTime(2026, 1, 1, 23)), 'Good evening!');
    });
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    List<Override> extraOverrides = const <Override>[],
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    // Phone-sized viewport, like the real device.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          readAloudProvider.overrideWithValue((_) {}),
          ...extraOverrides,
        ],
        child: const MaterialApp(home: JobsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the header greets by the current time of day', (tester) async {
    await pumpHome(tester);

    // Whichever greeting the clock calls for — exact wording is covered by
    // the greetingFor unit tests above; here we prove the header shows one
    // of them instead of a hardcoded string.
    expect(
      find.textContaining(RegExp(r'^Good (morning|afternoon|evening)!$')),
      findsOneWidget,
    );
  });

  testWidgets('the search bar sits above the tip card', (tester) async {
    await pumpHome(tester);

    final searchTop = tester.getTopLeft(find.byType(TextField)).dy;
    final tipTop = tester.getTopLeft(find.text('Apply with your voice')).dy;
    expect(searchTop, lessThan(tipTop));

    // It offers a plain text hint and a clear button, no mic.
    expect(find.text(AppStrings.jobsSearchHint), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);
  });

  testWidgets('every category chip label is fully visible', (tester) async {
    await pumpHome(tester);

    const labels = <String>[
      'All',
      'Remote',
      'Step-free',
      'With Support',
      AppStrings.filterMySupport,
    ];
    for (final label in labels) {
      final finder = find.text(label);
      expect(finder, findsOneWidget, reason: 'missing category "$label"');

      // Laid out with real size and inside the viewport — nothing clipped
      // by a fixed-height row.
      final size = tester.getSize(finder);
      expect(size.width, greaterThan(0), reason: '"$label" has no width');
      expect(
        tester.getTopRight(finder).dx,
        lessThanOrEqualTo(360),
        reason: '"$label" is cut off at the screen edge',
      );
    }
  });

  testWidgets('job cards share the screen scroll view and scroll from the top',
      (tester) async {
    await pumpHome(tester);

    // One scroll view holds the header, search, tip, filters and cards.
    final scroll = find.byType(CustomScrollView);
    expect(scroll, findsOneWidget);
    expect(
      find.descendant(of: scroll, matching: find.byType(TextField)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: scroll,
        matching: find.byTooltip(AppStrings.readJobAloud),
      ),
      findsWidgets,
      reason: 'job cards must live inside the same scroll view as the header',
    );

    // The scroll view that holds the job cards (the text field hosts a
    // Scrollable of its own, so anchor on the SliverList instead).
    final scrollable = find.ancestor(
      of: find.byType(SliverList),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      greaterThan(0),
      reason: 'the screen must actually scroll',
    );

    // Dragging moves the cards, proving they scroll from the very top
    // together with everything above them.
    final card = find.byTooltip(AppStrings.readJobAloud).first;
    final cardTopBefore = tester.getTopLeft(card).dy;
    await tester.drag(scroll, const Offset(0, -250));
    await tester.pumpAndSettle();
    final cardTopAfter = tester.getTopLeft(card).dy;
    expect(cardTopAfter, lessThan(cardTopBefore));
  });
}
