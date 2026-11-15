import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sync_accessibility/core/providers/app_providers.dart';
import 'package:sync_accessibility/features/onboarding/support_preferences_screen.dart';

// The support screen's bottom row ("Skip this step" / "Continue →") used to
// overflow horizontally: the two labels needed ~434px inside the 320px left
// by page padding at 360dp, and it only got worse with larger fonts. The
// buttons now split the row evenly and scale their labels down to fit, so no
// viewport or text scale can push them over the edge.
void main() {
  for (final scale in <double>[1.0, 1.3, 2.0]) {
    for (final size in <Size>[const Size(360, 800), const Size(320, 640)]) {
      testWidgets('support screen never overflows at scale=$scale size=$size',
          (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final prefs = await SharedPreferences.getInstance();

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Collect layout errors instead of letting the framework abort the
        // pump, so one failure reports every overflowing widget it found.
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError =
            (details) => errors.add(details.exception.toString());
        addTearDown(() => FlutterError.onError = previous);

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: const SupportPreferencesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(errors, isEmpty, reason: errors.join('\n'));

        // Both actions stay present and tappable after the layout change.
        expect(find.text('Skip this step'), findsOneWidget);
        expect(find.text('Continue →'), findsOneWidget);
      });
    }
  }
}
