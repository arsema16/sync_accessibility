import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/features/jobs/jobs_screen.dart';

void main() {
  Future<List<String>> pumpJobs(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final spoken = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          readAloudProvider.overrideWithValue(spoken.add),
        ],
        child: const MaterialApp(home: JobsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return spoken;
  }

  testWidgets('every job card offers a read-aloud button', (tester) async {
    await pumpJobs(tester);

    // The seeded listings each carry a speaker action labelled for
    // screen readers and long-press tooltips.
    expect(find.byIcon(Icons.volume_up), findsWidgets);
    expect(find.byTooltip('Read this job aloud'), findsWidgets);
  });

  testWidgets('tapping the speaker reads that job aloud', (tester) async {
    final spoken = await pumpJobs(tester);
    expect(spoken, isEmpty);

    // Target by tooltip: the hero tip card also carries a volume_up icon,
    // but only job cards use the "Read this job aloud" affordance.
    final speaker = find.byTooltip('Read this job aloud').first;
    await tester.ensureVisible(speaker);
    await tester.tap(speaker);
    await tester.pump();

    // The spoken summary mirrors the visible card: title first, then the
    // employer, location and accommodation tags.
    expect(spoken, hasLength(1));
    expect(spoken.single, contains('Warehouse assistant'));
    expect(spoken.single, contains('Tags:'));
  });
}
