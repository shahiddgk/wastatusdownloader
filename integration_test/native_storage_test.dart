import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whatsapp_status_saver/platform/method_channel_status_scanner.dart';

// This is a physical-device acceptance test. Before running it, connect
// WhatsApp Media in the app: Android opens its system picker near the folder,
// then the tester taps "Use this folder" and "Allow" once. The persisted SAF
// grant should remain available after an app restart.
//
// Run with:
// flutter test integration_test/native_storage_test.dart \
//   --dart-define=RUN_NATIVE_SAF_TEST=true -d <android-device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'discovers a real status through the persisted WhatsApp Media grant',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      const platform = MethodChannelStatusScanner();
      final access = await platform.checkFolderAccess();
      expect(
        access.hasAccess,
        isTrue,
        reason:
            'Connect WhatsApp Media in the app, tap "Use this folder", then '
            '"Allow", restart the app, and rerun this test.',
      );
      expect(access.treeUri, isNotNull);
      expect(access.resolvedStatusesDocId, isNotNull);

      final statuses = await platform.getStatuses();
      expect(
        statuses,
        isNotEmpty,
        reason: 'View at least one WhatsApp status before running this test.',
      );

      final item = statuses.first;
      final thumbnail = await platform.getThumbnail(
        id: item.id,
        isVideo: item.isVideo,
      );
      expect(thumbnail, isNotEmpty);

      if (item.isVideo) {
        final playback = await platform.prepareVideo(
          id: item.id,
          sizeBytes: item.sizeBytes,
        );
        expect(playback, isNotEmpty);
      }
    },
    skip: !const bool.fromEnvironment('RUN_NATIVE_SAF_TEST'),
  );
}
