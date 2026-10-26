import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_status_saver/app/app.dart';
import 'package:whatsapp_status_saver/application/access/access_notifier.dart';
import 'package:whatsapp_status_saver/application/access/access_state.dart';
import 'package:whatsapp_status_saver/application/providers.dart';
import 'package:whatsapp_status_saver/application/statuses/status_list_notifier.dart';
import 'package:whatsapp_status_saver/application/statuses/status_list_state.dart';
import 'package:whatsapp_status_saver/application/updates/required_update_controller.dart';
import 'package:whatsapp_status_saver/domain/entities/status_item.dart';
import 'package:whatsapp_status_saver/presentation/common/buttons/keep_button.dart';
import 'package:whatsapp_status_saver/presentation/kept/kept_vault_screen.dart';
import 'package:whatsapp_status_saver/presentation/moments/moments_screen.dart';
import 'package:whatsapp_status_saver/presentation/moments/status_card.dart';
import 'package:whatsapp_status_saver/presentation/onboarding/permission_onboarding_screen.dart';
import 'package:whatsapp_status_saver/presentation/settings/settings_screen.dart';
import 'package:whatsapp_status_saver/presentation/viewer/media_viewer_screen.dart';

class MockAccessNotifier extends AccessNotifier {
  final AccessState initialState;

  MockAccessNotifier([this.initialState = const AccessInitial()]);

  @override
  AccessState build() => initialState;

  @override
  Future<void> checkAccess({String targetPackage = ''}) async {}
}

class MockStatusListNotifier extends StatusListNotifier {
  final StatusListState initialState;

  MockStatusListNotifier([this.initialState = const StatusListInitial()]);

  @override
  StatusListState build() => initialState;

  @override
  Future<void> load({String targetPackage = '', String? treeUri}) async {}
}

void main() {
  final testItem = StatusItem(
    id: 'app_test_stat',
    displayName: 'test_moment.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 1024 * 300,
    lastModified: DateTime.now(),
    isVideo: false,
    isSaved: true,
  );

  Widget buildTestable({
    required AccessState accessState,
    List<StatusItem> items = const [],
    RequiredUpdateController? updateController,
    _AppUpdatePlatform? updatePlatform,
  }) {
    assert(updateController == null || updatePlatform == null);
    final controller =
        updateController ??
        RequiredUpdateController(updatePlatform ?? _AppUpdatePlatform());
    addTearDown(controller.dispose);
    return ProviderScope(
      overrides: [
        savedStatusesProvider.overrideWith(
          (ref) async => items.where((i) => i.isSaved).toList(),
        ),
        accessNotifierProvider.overrideWith(
          () => MockAccessNotifier(accessState),
        ),
        statusListNotifierProvider.overrideWith(
          () => MockStatusListNotifier(StatusListSuccess(items: items)),
        ),
      ],
      child: StatusSaverApp(updateController: controller),
    );
  }

  group('Phase 2E-B8: StatusSaverApp Top-Level Integration', () {
    testWidgets(
      'renders PermissionOnboardingScreen when access is not granted',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(800, 1000);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestable(accessState: const AccessNotGranted()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PermissionOnboardingScreen), findsOneWidget);
        expect(
          find.byKey(const Key('connect_whatsapp_media_button')),
          findsOneWidget,
        );
        expect(find.byType(MomentsScreen), findsNothing);
      },
    );

    testWidgets('renders MomentsScreen in AppShell when access is granted', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestable(accessState: const AccessGranted(), items: [testItem]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MomentsScreen), findsOneWidget);
      expect(find.text('All (1)'), findsOneWidget);
      expect(find.byType(StatusCard), findsOneWidget);
    });

    testWidgets('bottom navigation switches to Saved and Settings', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800); // phone
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestable(accessState: const AccessGranted(), items: [testItem]),
      );
      await tester.pumpAndSettle();

      // Switch to Kept tab
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Saved'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KeptVaultScreen), findsOneWidget);
      expect(find.text('All (1)'), findsOneWidget);

      // Switch to Settings tab
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Settings'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Status access'), findsOneWidget);
    });

    testWidgets('tapping status card in Moments opens MediaViewerScreen', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestable(accessState: const AccessGranted(), items: [testItem]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StatusCard));
      await tester.pumpAndSettle();

      expect(find.byType(MediaViewerScreen), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(
        find.descendant(
          of: find.descendant(
            of: find.byType(MediaViewerScreen),
            matching: find.byType(KeepButton),
          ),
          matching: find.text('Saved'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'required update covers an open viewer and blocks system Back',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(800, 1000);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final platform = _AppUpdatePlatform();
        final controller = RequiredUpdateController(platform);

        await tester.pumpWidget(
          buildTestable(
            accessState: const AccessGranted(),
            items: [testItem],
            updateController: controller,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(StatusCard));
        await tester.pumpAndSettle();
        expect(find.byType(MediaViewerScreen), findsOneWidget);

        platform.status = const PlayUpdateStatus(
          available: true,
          availableVersionCode: 17,
        );
        await controller.refresh();
        await tester.pumpAndSettle();

        expect(find.text('Update required'), findsOneWidget);
        expect(find.byType(MediaViewerScreen), findsNothing);
        expect(
          find.byType(MediaViewerScreen, skipOffstage: false),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Update required'), findsOneWidget);
        expect(find.byType(MediaViewerScreen), findsNothing);
        expect(
          find.byType(MediaViewerScreen, skipOffstage: false),
          findsOneWidget,
        );
        expect(platform.requiredVersion, 17);
      },
    );

    testWidgets('required update covers onboarding when storage is denied', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final platform = _AppUpdatePlatform()..requiredVersion = 17;

      await tester.pumpWidget(
        buildTestable(
          accessState: const AccessNotGranted(),
          updatePlatform: platform,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update required'), findsOneWidget);
      expect(find.byType(PermissionOnboardingScreen), findsNothing);
      expect(
        find.byType(PermissionOnboardingScreen, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('connect_whatsapp_media_button')),
        findsNothing,
      );
    });
  });
}

class _AppUpdatePlatform implements UpdatePlatform {
  int? requiredVersion;
  PlayUpdateStatus status = const PlayUpdateStatus(available: false);

  @override
  Future<int> installedVersionCode() async => 16;

  @override
  Future<int?> readRequiredVersionCode() async => requiredVersion;

  @override
  Future<void> writeRequiredVersionCode(int? versionCode) async {
    requiredVersion = versionCode;
  }

  @override
  Future<PlayUpdateStatus> checkForUpdate() async => status;

  @override
  Future<UpdateAttempt> performImmediateUpdate() async =>
      UpdateAttempt.cancelled;

  @override
  Future<bool> openStore() async => true;
}
