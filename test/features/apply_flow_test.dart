import 'package:flutter_test/flutter_test.dart';

import 'package:sync_accessibility/features/jobs/apply_job_screen.dart';
import 'package:sync_accessibility/models/job_model.dart';

void main() {
  group('ApplyJobScreen.buildCoverNote', () {
    test('joins both answers with a newline', () {
      final note = ApplyJobScreen.buildCoverNote(<String, Object>{
        'why': 'I like working with people',
        'experience': 'Two years in retail',
      });

      expect(note, 'I like working with people\nTwo years in retail');
    });

    test('skips the optional experience answer when empty', () {
      final note = ApplyJobScreen.buildCoverNote(<String, Object>{
        'why': 'I need this job',
        'experience': '   ',
      });

      expect(note, 'I need this job');
    });

    test('returns an empty string when both answers are empty', () {
      final note = ApplyJobScreen.buildCoverNote(<String, Object>{
        'why': '',
        'experience': '',
      });

      expect(note, isEmpty);
    });
  });

  test('ApplyJobScreen is constructible with a job', () {
    const job = Job(id: 'j1', title: 'Waiter', employer: 'Cafe X');
    const screen = ApplyJobScreen(job: job);
    expect(screen.job, job);
  });
}
