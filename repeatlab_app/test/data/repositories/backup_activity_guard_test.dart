import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/data/repositories/backup_activity_guard.dart';

void main() {
  tearDown(BackupActivityGuard.reset);

  group('BackupActivityGuard', () {
    test('isActive is false before run', () {
      expect(BackupActivityGuard.isActive, isFalse);
    });

    test('isActive is true while the action runs and false after', () async {
      final activeDuringRun = <bool>[];

      final result = await BackupActivityGuard.run(() async {
        activeDuringRun.add(BackupActivityGuard.isActive);
        return 42;
      });

      expect(activeDuringRun, [true]);
      expect(result, 42);
      expect(BackupActivityGuard.isActive, isFalse);
    });

    test('isActive is cleared even when the action throws', () async {
      await expectLater(
        BackupActivityGuard.run<void>(() => throw Exception('boom')),
        throwsA(isException),
      );

      expect(BackupActivityGuard.isActive, isFalse);
    });
  });
}
