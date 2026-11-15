import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig.isConfigured', () {
    test('is false when either value is missing', () {
      expect(
        const SupabaseConfig(url: '', anonKey: '').isConfigured,
        isFalse,
      );
      expect(
        const SupabaseConfig(
          url: 'https://abc.supabase.co',
          anonKey: '',
        ).isConfigured,
        isFalse,
      );
      expect(
        const SupabaseConfig(url: '', anonKey: 'key').isConfigured,
        isFalse,
      );
    });

    test('treats a well-formed placeholder as configured', () {
      const example = SupabaseConfig(
        url: 'https://YOUR-PROJECT-REF.supabase.co',
        anonKey: 'YOUR-ANON-KEY',
      );
      // The placeholder parses as a URL, so it counts as configured; a real
      // run then fails to connect, which SupabaseBootstrap reports clearly
      // before falling back to local storage.
      expect(example.isConfigured, isTrue);
    });

    test('is false when the URL has no scheme or host', () {
      expect(
        const SupabaseConfig(
          url: 'abc.supabase.co',
          anonKey: 'key',
        ).isConfigured,
        isFalse,
      );
      expect(
        const SupabaseConfig(url: 'not a url', anonKey: 'key').isConfigured,
        isFalse,
      );
    });

    test('is true for a well-formed project URL and key', () {
      expect(
        const SupabaseConfig(
          url: 'https://abcdefgh.supabase.co',
          anonKey: 'eyJhbGciOiJIUzI1NiJ9.example',
        ).isConfigured,
        isTrue,
      );
    });
  });

  test('SupabaseBootstrap is not ready before initialize()', () {
    // Tests never call initialize() with credentials, so the app must use
    // the in-memory fallbacks (this is what keeps `flutter test` offline).
    expect(SupabaseBootstrap.isReady, isFalse);
    expect(SupabaseBootstrap.useSupabase, isFalse);
  });
}
