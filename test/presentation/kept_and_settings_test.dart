import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_status_saver/app/theme/app_theme.dart';
import 'package:whatsapp_status_saver/application/access/access_notifier.dart';
import 'package:whatsapp_status_saver/application/access/access_state.dart';
import 'package:whatsapp_status_saver/application/providers.dart';
import 'package:whatsapp_status_saver/application/statuses/status_list_notifier.dart';
import 'package:whatsapp_status_saver/application/statuses/status_list_state.dart';
import 'package:whatsapp_status_saver/domain/entities/status_item.dart';
import 'package:whatsapp_status_saver/presentation/common/feedback/empty_state.dart';
import 'package:whatsapp_status_saver/presentation/kept/kept_vault_screen.dart';
import 'package:whatsapp_status_saver/presentation/moments/status_card.dart';
import 'package:whatsapp_status_saver/presentation/settings/settings_screen.dart';

class MockAccessNotifier extends AccessNotifier {
  final AccessState initialState;
  bool requested = false;

  MockAccessNotifier([this.initialState = const AccessInitial()]);

  @override
  AccessState build() => initialState;

  @override
  Future<void> requestAccess({String targetPackage = ''}) async {
    requested = true;
  }
}

class MockStatusListNotifier extends StatusListNotifier {
  final StatusListState initialState;

  MockStatusListNotifier([this.initialState = const StatusListInitial()]);

  @override
  StatusListState build() => initialState;
}

void main() {
  final unsavedItem = StatusItem(
    id: 'stat_unsaved',
    displayName: 'unsaved.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 1024 * 500,
    lastModified: DateTime.now(),
    isVideo: false,
    isSaved: false,
  );

  final savedImage = StatusItem(
    id: 'stat_saved_img',
    displayName: 'saved.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 1024 * 1024, // 1MB
    lastModified: DateTime.now(),
    isVideo: false,
    isSaved: true,
  );

  final savedVideo = StatusItem(
    id: 'stat_saved_vid',
    displayName: 'saved.mp4',
    mimeType: 'video/mp4',
    sizeBytes: 1024 * 1024 * 4, // 4MB
    lastModified: DateTime.now(),
    isVideo: true,
    isSaved: true,
  );

  Widget buildTestable(
    Widget child, {
    MockAccessNotifier? mockAccessNotifier,
    MockStatusListNotifier? mockStatusListNotifier,
  }) {
    return ProviderScope(
      overrides: [
        savedStatusesProvider.overrideWith(
          (ref) async =>
              mockStatusListNotifier?.initialState.items
                  .where((i) => i.isSaved)
                  .toList() ??
              [],
        ),
        if (mockAccessNotifier != null)
          accessNotifierProvider.overrideWith(() => mockAccessNotifier),
        if (mockStatusListNotifier != null)
          statusListNotifierProvider.overrideWith(() => mockStatusListNotifier),
      ],
      child: MaterialApp(theme: KeevaTheme.darkTheme, home: child),
    );
  }

  group('Phase 2E-B6: Kept Vault & Settings', () {
    // =========================================================================
    // KEPT VAULT SCREEN
    // =========================================================================
    group('KeptVaultScreen', () {
      testWidgets('renders EmptyState when no moments have been kept', (
        tester,
      ) async {
        final listMock = MockStatusListNotifier(
          StatusListSuccess(items: [unsavedItem]),
        );
        var explored = false;

        await tester.pumpWidget(
          buildTestable(
            KeptVaultScreen(onExploreMoments: () => explored = true),
            mockStatusListNotifier: listMock,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Saved'), findsOneWidget);
        expect(find.byType(EmptyState), findsOneWidget);
        expect(find.text('No saved statuses'), findsOneWidget);
        expect(find.text('View statuses'), findsOneWidget);

        await tester.tap(find.text('View statuses'));
        await tester.pump();
        expect(explored, isTrue);
      });

      testWidgets(
        'renders only saved items with storage footprint and filters',
        (tester) async {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(800, 1000);
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final listMock = MockStatusListNotifier(
            StatusListSuccess(items: [unsavedItem, savedImage, savedVideo]),
          );

          await tester.pumpWidget(
            buildTestable(
              const KeptVaultScreen(),
              mockStatusListNotifier: listMock,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('All (2)'), findsOneWidget);
          expect(find.text('Photos (1)'), findsOneWidget);
          expect(find.text('Videos (1)'), findsOneWidget);
          expect(find.byType(StatusCard), findsNWidgets(2));

          // Filter Photos
          await tester.tap(find.text('Photos (1)'));
          await tester.pumpAndSettle();
          expect(find.byType(StatusCard), findsOneWidget);

          // Filter Videos
          await tester.tap(find.text('Videos (1)'));
          await tester.pumpAndSettle();
          expect(find.byType(StatusCard), findsOneWidget);
        },
      );
    });

    // =========================================================================
    // SETTINGS SCREEN
    // =========================================================================
    group('SettingsScreen', () {
      testWidgets('shows access and only functional theme choices', (
        tester,
      ) async {
        ThemeMode? chosen;
        await tester.pumpWidget(
          buildTestable(
            SettingsScreen(onThemeModeChanged: (mode) => chosen = mode),
            mockAccessNotifier: MockAccessNotifier(const AccessGranted()),
          ),
        );
        expect(find.text('Allowed'), findsOneWidget);
        expect(find.text('Original Bitrate Preservation'), findsNothing);
        expect(find.textContaining('Encryption'), findsNothing);
        await tester.tap(find.text('Dark theme'));
        expect(chosen, ThemeMode.dark);
      });

      testWidgets('requests missing access', (tester) async {
        final mock = MockAccessNotifier(const AccessNotGranted());
        await tester.pumpWidget(
          buildTestable(const SettingsScreen(), mockAccessNotifier: mock),
        );
        await tester.tap(find.text('Status access'));
        expect(mock.requested, isTrue);
      });

      testWidgets(
        'Saved uses saved copies even when current statuses are empty',
        (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                statusListNotifierProvider.overrideWith(
                  () => MockStatusListNotifier(const StatusListEmpty()),
                ),
                savedStatusesProvider.overrideWith((ref) async => [savedImage]),
              ],
              child: MaterialApp(
                theme: KeevaTheme.darkTheme,
                home: const KeptVaultScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(StatusCard), findsOneWidget);
          expect(find.text('All (1)'), findsOneWidget);
        },
      );
    });
  });
}
