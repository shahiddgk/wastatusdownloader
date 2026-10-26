import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_status_saver/application/updates/required_update_controller.dart';

const _newVersion = PlayUpdateStatus(
  available: true,
  availableVersionCode: 17,
  immediateAllowed: true,
);
const _noUpdate = PlayUpdateStatus(available: false);

void main() {
  test('the first check gates entry until initialization finishes', () async {
    final platform = _FakeUpdatePlatform();
    final check = Completer<PlayUpdateStatus>();
    platform.pendingCheck = check;
    final controller = RequiredUpdateController(platform);
    addTearDown(controller.dispose);

    expect(controller.blocksApp, isTrue);
    final operation = controller.refresh();
    expect(controller.checking, isTrue);
    expect(controller.blocksApp, isTrue);
    check.complete(_noUpdate);
    await operation;

    expect(controller.blocksApp, isFalse);
    expect(controller.checking, isFalse);
    expect(controller.busy, isFalse);
  });

  test(
    'a cancelled immediate update stays required and is saved first',
    () async {
      final platform = _FakeUpdatePlatform()..status = _newVersion;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(platform.events, containsAllInOrder(['save:17', 'immediate']));
      expect(platform.savedVersion, 17);
      expect(controller.required, isTrue);
      expect(controller.blocksApp, isTrue);
      expect(controller.message, contains('cancelled'));
      expect(platform.storeOpens, 0);

      await controller.refresh();
      expect(platform.immediateAttempts, 1);
      expect(controller.blocksApp, isTrue);
    },
  );

  test(
    'a saved requirement survives restart and offline Play errors',
    () async {
      final platform = _FakeUpdatePlatform()..status = _newVersion;
      final first = RequiredUpdateController(platform);
      await first.refresh();
      first.dispose();

      platform.checkFails = true;
      final restarted = RequiredUpdateController(platform);
      addTearDown(restarted.dispose);
      await restarted.refresh();

      expect(restarted.targetVersion, 17);
      expect(restarted.blocksApp, isTrue);
      expect(restarted.message, contains('Connect to Google Play'));
    },
  );

  test(
    'not available and stale responses cannot clear an unmet minimum',
    () async {
      final platform = _FakeUpdatePlatform()..savedVersion = 18;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.blocksApp, isTrue);
      platform.status = const PlayUpdateStatus(
        available: true,
        availableVersionCode: 16,
      );
      await controller.refresh();
      expect(controller.targetVersion, 18);
      expect(platform.savedVersion, 18);
      expect(controller.blocksApp, isTrue);
    },
  );

  test('known minimum versions only increase before installation', () async {
    final platform = _FakeUpdatePlatform()
      ..savedVersion = 18
      ..status = _newVersion;
    final controller = RequiredUpdateController(platform);
    addTearDown(controller.dispose);

    await controller.refresh();
    expect(controller.targetVersion, 18);
    platform.status = const PlayUpdateStatus(
      available: true,
      availableVersionCode: 19,
    );
    await controller.refresh();
    expect(controller.targetVersion, 19);
    expect(platform.savedVersion, 19);
  });

  test(
    'an installed version satisfying the minimum clears it even offline',
    () async {
      final platform = _FakeUpdatePlatform()
        ..savedVersion = 17
        ..installedVersion = 17
        ..checkFails = true;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.blocksApp, isFalse);
      expect(controller.targetVersion, isNull);
      expect(platform.savedVersion, isNull);
      expect(platform.immediateAttempts, 0);
    },
  );

  test(
    'failure to clear a satisfied preference does not reject installation',
    () async {
      final platform = _FakeUpdatePlatform()
        ..savedVersion = 17
        ..installedVersion = 18
        ..writeFails = true;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.blocksApp, isFalse);
      expect(platform.savedVersion, 17);
    },
  );

  test(
    'persistence failure retains the gate and prevents starting installation',
    () async {
      final platform = _FakeUpdatePlatform()
        ..status = _newVersion
        ..writeFails = true;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.targetVersion, 17);
      expect(controller.blocksApp, isTrue);
      expect(platform.immediateAttempts, 0);
      expect(controller.message, contains('Could not prepare'));

      platform.writeFails = false;
      await controller.update();
      expect(platform.savedVersion, 17);
      expect(platform.immediateAttempts, 1);
    },
  );

  test(
    'unknown Play target gates in memory without inventing a version',
    () async {
      final platform = _FakeUpdatePlatform()
        ..status = const PlayUpdateStatus(
          available: true,
          immediateAllowed: true,
        );
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.blocksApp, isTrue);
      expect(controller.targetVersion, isNull);
      expect(
        platform.events.where((event) => event.startsWith('save:')),
        isEmpty,
      );

      platform.status = _noUpdate;
      await controller.refresh();
      expect(controller.blocksApp, isTrue);
      platform.checkFails = true;
      await controller.refresh();
      expect(controller.blocksApp, isTrue);
    },
  );

  test(
    'an in-progress immediate update resumes even if availability is false',
    () async {
      final platform = _FakeUpdatePlatform()
        ..status = const PlayUpdateStatus(
          available: false,
          availableVersionCode: 17,
          inProgress: true,
        );
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(platform.immediateAttempts, 1);
      expect(platform.savedVersion, 17);
      expect(controller.blocksApp, isTrue);
    },
  );

  test('user retry fresh-checks Play and opens store when immediate is unavailable', () async {
    final platform = _FakeUpdatePlatform()
      ..savedVersion = 17
      ..checkFails = true;
    final controller = RequiredUpdateController(platform);
    addTearDown(controller.dispose);

    await controller.refresh();
    expect(platform.storeOpens, 0);
    await controller.update();

    expect(platform.checks, 2);
    expect(platform.storeOpens, 1);
    expect(controller.blocksApp, isTrue);
    expect(controller.message, contains('Google Play'));
  });

  test(
    'automatic failure stays gated and only user retry opens the store',
    () async {
      final platform = _FakeUpdatePlatform()
        ..status = _newVersion
        ..attempt = UpdateAttempt.failed;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(platform.storeOpens, 0);
      expect(controller.blocksApp, isTrue);
      await controller.update();
      expect(platform.storeOpens, 1);
      expect(controller.blocksApp, isTrue);
    },
  );

  test('reported success alone cannot clear a minimum version', () async {
    final platform = _FakeUpdatePlatform()
      ..status = _newVersion
      ..attempt = UpdateAttempt.success;
    final controller = RequiredUpdateController(platform);
    addTearDown(controller.dispose);

    await controller.refresh();

    expect(controller.blocksApp, isTrue);
    expect(platform.savedVersion, 17);
    platform.installedVersion = 17;
    platform.status = _noUpdate;
    await controller.refresh();
    expect(controller.blocksApp, isFalse);
    expect(platform.savedVersion, isNull);
  });

  test(
    'only confirmed installation after immediate success removes the gate',
    () async {
      final platform = _FakeUpdatePlatform()
        ..status = _newVersion
        ..attempt = UpdateAttempt.success
        ..installedAfterImmediate = 17;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.blocksApp, isFalse);
      expect(platform.savedVersion, isNull);
    },
  );

  test(
    'concurrent refresh and retry share one operation and one Play dialog',
    () async {
      final platform = _FakeUpdatePlatform();
      final check = Completer<PlayUpdateStatus>();
      final update = Completer<UpdateAttempt>();
      platform.pendingCheck = check;
      platform.pendingAttempt = update;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      final first = controller.refresh();
      expect(identical(first, controller.update()), isTrue);
      check.complete(_newVersion);
      await Future<void>.delayed(Duration.zero);
      expect(identical(first, controller.refresh()), isTrue);
      expect(platform.immediateAttempts, 1);
      update.complete(UpdateAttempt.cancelled);
      await first;

      expect(platform.checks, 1);
      expect(controller.busy, isFalse);
      expect(controller.blocksApp, isTrue);
    },
  );

  testWidgets(
    'an unverified offline first launch is bounded and remains usable',
    (tester) async {
      final platform = _FakeUpdatePlatform()
        ..pendingCheck = Completer<PlayUpdateStatus>();
      final controller = RequiredUpdateController(
        platform,
        queryTimeout: const Duration(seconds: 10),
      );
      addTearDown(controller.dispose);

      final checking = controller.refresh();
      await tester.pump(const Duration(seconds: 11));
      await checking;

      expect(controller.blocksApp, isFalse);
      expect(controller.checking, isFalse);
    },
  );

  test(
    'offline failure without a known newer version does not force an update',
    () async {
      final platform = _FakeUpdatePlatform()..checkFails = true;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.blocksApp, isFalse);
      expect(platform.storeOpens, 0);
    },
  );

  test('missing installed version cannot clear a saved requirement', () async {
    final platform = _FakeUpdatePlatform()
      ..savedVersion = 17
      ..installedFails = true;
    final controller = RequiredUpdateController(platform);
    addTearDown(controller.dispose);

    await controller.refresh();

    expect(controller.blocksApp, isTrue);
    expect(platform.savedVersion, 17);
  });

  test(
    'a local preference read failure blocks until a successful retry',
    () async {
      final platform = _FakeUpdatePlatform()..readFails = true;
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.blocksApp, isTrue);
      expect(controller.required, isFalse);
      expect(controller.checking, isFalse);
      expect(controller.message, contains('Could not verify'));

      platform.readFails = false;
      await controller.update();
      expect(controller.blocksApp, isFalse);
      expect(platform.storeOpens, 0);
    },
  );

  test(
    'an unknown target clears only when a later actual target is installed',
    () async {
      final platform = _FakeUpdatePlatform()
        ..status = const PlayUpdateStatus(available: true);
      final controller = RequiredUpdateController(platform);
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.blocksApp, isTrue);
      platform.status = const PlayUpdateStatus(
        available: true,
        availableVersionCode: 17,
      );
      await controller.refresh();
      expect(controller.blocksApp, isTrue);
      expect(platform.savedVersion, 17);
      platform.installedVersion = 17;
      platform.status = _noUpdate;
      await controller.refresh();
      expect(controller.blocksApp, isFalse);
    },
  );

  test(
    'dispose during a query prevents notifications and launching a dialog',
    () async {
      final platform = _FakeUpdatePlatform();
      final check = Completer<PlayUpdateStatus>();
      platform.pendingCheck = check;
      final controller = RequiredUpdateController(platform);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final operation = controller.refresh();
      controller.dispose();
      final beforeCompletion = notifications;

      check.complete(_newVersion);
      await operation;

      expect(notifications, beforeCompletion);
      expect(platform.immediateAttempts, 0);
      expect(platform.storeOpens, 0);
    },
  );
}

class _FakeUpdatePlatform implements UpdatePlatform {
  int installedVersion = 16;
  int? savedVersion;
  PlayUpdateStatus status = _noUpdate;
  UpdateAttempt attempt = UpdateAttempt.cancelled;
  int? installedAfterImmediate;
  bool installedFails = false;
  bool readFails = false;
  bool checkFails = false;
  bool writeFails = false;
  int checks = 0;
  int immediateAttempts = 0;
  int storeOpens = 0;
  final events = <String>[];
  Completer<PlayUpdateStatus>? pendingCheck;
  Completer<UpdateAttempt>? pendingAttempt;

  @override
  Future<int> installedVersionCode() async {
    if (installedFails) throw StateError('No package information');
    return installedVersion;
  }

  @override
  Future<int?> readRequiredVersionCode() async {
    if (readFails) throw StateError('Storage unavailable');
    return savedVersion;
  }

  @override
  Future<void> writeRequiredVersionCode(int? versionCode) async {
    events.add('save:$versionCode');
    if (writeFails) throw StateError('Storage unavailable');
    savedVersion = versionCode;
  }

  @override
  Future<PlayUpdateStatus> checkForUpdate() async {
    checks++;
    events.add('check');
    if (checkFails) throw StateError('Google Play unavailable');
    return pendingCheck == null ? status : await pendingCheck!.future;
  }

  @override
  Future<UpdateAttempt> performImmediateUpdate() async {
    immediateAttempts++;
    events.add('immediate');
    final result = pendingAttempt == null
        ? attempt
        : await pendingAttempt!.future;
    if (installedAfterImmediate case final version?) installedVersion = version;
    return result;
  }

  @override
  Future<bool> openStore() async {
    storeOpens++;
    events.add('store');
    return true;
  }
}
