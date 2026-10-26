import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_status_saver/application/updates/required_update_controller.dart';
import 'package:whatsapp_status_saver/platform/play_update_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const nativeChannel = MethodChannel('ratedwhats.appstatusdownloader/updates');
  const platform = PlayUpdatePlatform();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(nativeChannel, null);
  });

  test(
    'native calls use typed positive version codes and an explicit clear',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(nativeChannel, (call) async {
        calls.add(call);
        return switch (call.method) {
          'getInstalledVersionCode' => 16,
          'getRequiredVersionCode' => 20,
          'openStore' => true,
          _ => null,
        };
      });

      expect(await platform.installedVersionCode(), 16);
      expect(await platform.readRequiredVersionCode(), 20);
      await platform.writeRequiredVersionCode(21);
      await platform.writeRequiredVersionCode(null);
      expect(await platform.openStore(), isTrue);
      expect(calls.map((call) => call.method), [
        'getInstalledVersionCode',
        'getRequiredVersionCode',
        'setRequiredVersionCode',
        'setRequiredVersionCode',
        'openStore',
      ]);
      expect(calls[2].arguments, {'versionCode': 21});
      expect(calls[3].arguments, {'versionCode': null});
    },
  );

  test(
    'nullable requirement differs from a malformed native version code',
    () async {
      Object? value;
      messenger.setMockMethodCallHandler(nativeChannel, (_) async => value);
      expect(await platform.readRequiredVersionCode(), isNull);
      await expectLater(platform.installedVersionCode(), throwsFormatException);
      for (final invalid in [0, -1, 16.0, '16', true]) {
        value = invalid;
        await expectLater(
          platform.installedVersionCode(),
          throwsFormatException,
        );
        await expectLater(
          platform.readRequiredVersionCode(),
          throwsFormatException,
        );
      }
      value = 3000000000;
      expect(await platform.installedVersionCode(), 3000000000);
    },
  );

  test('invalid writes never reach native persistence', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(nativeChannel, (_) async {
      calls++;
      return null;
    });
    await expectLater(
      platform.writeRequiredVersionCode(0),
      throwsArgumentError,
    );
    await expectLater(
      platform.writeRequiredVersionCode(-1),
      throwsArgumentError,
    );
    expect(calls, 0);
  });

  test('failed durable native write propagates to the controller', () async {
    messenger.setMockMethodCallHandler(nativeChannel, (_) async {
      throw PlatformException(code: 'UPDATE_PLATFORM_ERROR');
    });
    await expectLater(
      platform.writeRequiredVersionCode(20),
      throwsA(isA<PlatformException>()),
    );
  });

  test(
    'store launch preserves failure and rejects malformed responses',
    () async {
      Object? response = false;
      messenger.setMockMethodCallHandler(nativeChannel, (_) async => response);
      expect(await platform.openStore(), isFalse);
      response = null;
      await expectLater(platform.openStore(), throwsFormatException);
    },
  );

  test(
    'Google Play status preserves availability and in-progress state',
    () async {
      var available = true;
      var inProgress = false;
      int? version = 20;
      messenger.setMockMethodCallHandler(nativeChannel, (call) async {
        expect(call.method, 'checkForUpdate');
        return {
          'available': available,
          'inProgress': inProgress,
          'immediateAllowed': true,
          'availableVersionCode': version,
        };
      });
      var status = await platform.checkForUpdate();
      expect(status.available, isTrue);
      expect(status.availableVersionCode, 20);
      expect(status.immediateAllowed, isTrue);
      expect(status.inProgress, isFalse);
      inProgress = true;
      status = await platform.checkForUpdate();
      expect(status.inProgress, isTrue);
      available = false;
      inProgress = false;
      version = null;
      status = await platform.checkForUpdate();
      expect(status.available, isFalse);
      expect(status.availableVersionCode, isNull);
    },
  );

  test('malformed Google Play status is rejected', () async {
    Object? response;
    messenger.setMockMethodCallHandler(nativeChannel, (_) async => response);
    await expectLater(platform.checkForUpdate(), throwsFormatException);
    response = {
      'available': true,
      'inProgress': false,
      'immediateAllowed': 'true',
    };
    await expectLater(platform.checkForUpdate(), throwsFormatException);
    response = {
      'available': true,
      'inProgress': false,
      'immediateAllowed': true,
      'availableVersionCode': 0,
    };
    await expectLater(platform.checkForUpdate(), throwsFormatException);
  });

  test(
    'immediate update validates success, cancellation and failure',
    () async {
      Object? response = 'success';
      messenger.setMockMethodCallHandler(nativeChannel, (call) async {
        expect(call.method, 'performImmediateUpdate');
        return response;
      });
      expect(await platform.performImmediateUpdate(), UpdateAttempt.success);
      response = 'cancelled';
      expect(await platform.performImmediateUpdate(), UpdateAttempt.cancelled);
      response = 'failed';
      expect(await platform.performImmediateUpdate(), UpdateAttempt.failed);
      response = null;
      await expectLater(
        platform.performImmediateUpdate(),
        throwsFormatException,
      );
      response = 'unexpected';
      await expectLater(
        platform.performImmediateUpdate(),
        throwsFormatException,
      );
    },
  );
}
