import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whatsapp_status_saver/platform/method_channel_status_scanner.dart';

// Run only on a disposable Android emulator with All files access pre-granted.
// Fixture paths are deliberately test-only; production paths remain in Kotlin.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('discovers, previews and saves real media without a folder grant', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    const platform = MethodChannelStatusScanner();
    final access = await platform.checkFolderAccess();
    expect(
      access.hasAccess,
      isTrue,
      reason: 'Enable All files access on the test emulator first.',
    );
    expect(access.treeUri, isNull);

    const standardPath =
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
    const businessPath =
        '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses';
    final photo = File('$standardPath/codex-storage-test-photo.png');
    final video = File('$standardPath/codex-storage-test-video.mp4');
    final business = File('$businessPath/codex-storage-test-business.png');
    final partial = File('$standardPath/codex-storage-test-partial.jpg.tmp');
    final empty = File('$standardPath/codex-storage-test-empty.jpg');
    final fixtures = [photo, video, business, partial, empty];
    final savedCopies = <File>[];
    try {
      await photo.parent.create(recursive: true);
      await business.parent.create(recursive: true);
      final bytes = (await rootBundle.load('assets/icon/status_icon_512.png'))
          .buffer
          .asUint8List();
      await photo.writeAsBytes(bytes);
      await business.writeAsBytes(bytes);
      await partial.writeAsBytes(bytes);
      await empty.writeAsBytes([]);
      await video.writeAsBytes(
        base64Decode(
          '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',
        ),
      );

      final statuses = await platform.getStatuses();
      final imageItem = statuses.singleWhere(
        (item) => item.displayName == photo.uri.pathSegments.last,
      );
      final videoItem = statuses.singleWhere(
        (item) => item.displayName == video.uri.pathSegments.last,
      );
      expect(
        statuses.any(
          (item) => item.displayName == 'codex-storage-test-business.png',
        ),
        isFalse,
      );
      expect(
        statuses.any(
          (item) =>
              item.displayName == 'codex-storage-test-partial.jpg.tmp' ||
              item.displayName == 'codex-storage-test-empty.jpg',
        ),
        isFalse,
      );
      final businessItems = await platform.getStatuses(
        targetPackage: 'com.whatsapp.w4b',
      );
      expect(
        businessItems.any(
          (item) => item.displayName == business.uri.pathSegments.last,
        ),
        isTrue,
      );
      expect(businessItems.any((item) => item.id == imageItem.id), isFalse);

      for (final item in [imageItem, videoItem]) {
        final thumbnail = await platform.getThumbnail(
          id: item.id,
          isVideo: item.isVideo,
        );
        expect(await File(thumbnail).length(), greaterThan(0));
        if (item.isVideo) {
          final playback = await platform.prepareVideo(
            id: item.id,
            sizeBytes: item.sizeBytes,
          );
          expect(await File(playback).length(), item.sizeBytes);
        }
        final saved = await platform.saveStatus(
          id: item.id,
          displayName: item.displayName,
          mimeType: item.mimeType,
          isVideo: item.isVideo,
        );
        expect(saved.success, isTrue);
        expect(saved.bytesSaved, item.sizeBytes);
        savedCopies.add(
          File(
            '/storage/emulated/0/${saved.publicCollection}${saved.displayName}',
          ),
        );
      }
      await photo.delete();
      await video.delete();
      final saved = await platform.getSavedStatuses();
      for (final original in [imageItem, videoItem]) {
        final copy = saved.singleWhere(
          (item) => item.displayName == original.displayName,
        );
        expect(copy.isSaved, isTrue);
        expect(copy.sizeBytes, original.sizeBytes);
        expect(copy.id, isNot(original.id));
        expect(
          await File(
            await platform.getThumbnail(id: copy.id, isVideo: copy.isVideo),
          ).length(),
          greaterThan(0),
        );
      }
      final refreshed = await platform.getStatuses();
      expect(
        refreshed.any(
          (item) => item.id == imageItem.id || item.id == videoItem.id,
        ),
        isFalse,
      );
    } finally {
      for (final file in [...fixtures, ...savedCopies]) {
        if (await file.exists()) await file.delete();
      }
    }
  }, skip: !const bool.fromEnvironment('RUN_NATIVE_STORAGE_TEST'));
}
