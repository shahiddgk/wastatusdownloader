import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_status_saver/application/updates/required_update_controller.dart';
import 'package:whatsapp_status_saver/presentation/updates/required_update_gate.dart';
import 'package:whatsapp_status_saver/presentation/updates/required_update_navigation_observer.dart';

class _FakeUpdatePlatform implements UpdatePlatform {
  int installed = 16;
  int? saved;
  PlayUpdateStatus status = const PlayUpdateStatus(available: false);
  int storeLaunches = 0;
  int immediateAttempts = 0;
  bool offline = false;

  @override
  Future<int> installedVersionCode() async => installed;
  @override
  Future<int?> readRequiredVersionCode() async => saved;
  @override
  Future<void> writeRequiredVersionCode(int? versionCode) async {
    saved = versionCode;
  }

  @override
  Future<PlayUpdateStatus> checkForUpdate() async {
    if (offline) throw StateError('offline');
    return status;
  }

  @override
  Future<UpdateAttempt> performImmediateUpdate() async {
    immediateAttempts++;
    return UpdateAttempt.cancelled;
  }

  @override
  Future<bool> openStore() async {
    storeLaunches++;
    return true;
  }
}

void main() {
  late _FakeUpdatePlatform platform;
  late RequiredUpdateController controller;
  late RequiredUpdateNavigationObserver observer;
  late GlobalKey<NavigatorState> navigator;

  setUp(() {
    platform = _FakeUpdatePlatform();
    controller = RequiredUpdateController(platform);
    observer = RequiredUpdateNavigationObserver(controller);
    navigator = GlobalKey<NavigatorState>();
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [observer],
        builder: (context, child) =>
            RequiredUpdateGate(controller: controller, child: child!),
        home: Scaffold(
          body: TextButton(
            onPressed: () {},
            child: const Text('Private media library'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    observer.dispose();
    controller.dispose();
  });

  testWidgets('an up-to-date installation can access the app', (tester) async {
    await mount(tester);
    expect(find.text('Private media library'), findsOneWidget);
    expect(find.byKey(const Key('required_update_gate')), findsNothing);
    expect(platform.immediateAttempts, 0);
  });

  testWidgets('required update covers app and cannot be skipped with Back', (
    tester,
  ) async {
    platform.status = const PlayUpdateStatus(
      available: true,
      availableVersionCode: 17,
      immediateAllowed: true,
    );
    await mount(tester);
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
    expect(find.text('Private media library'), findsNothing);
    expect(platform.immediateAttempts, 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Update required'), findsOneWidget);
    expect(controller.blocksApp, isTrue);
    expect(platform.saved, 17);
  });

  testWidgets('gate blocks an already-open viewer and a dialog on resume', (
    tester,
  ) async {
    await mount(tester);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Full screen viewer')),
      ),
    );
    await tester.pumpAndSettle();
    final viewerContext = tester.element(find.text('Full screen viewer'));
    showDialog<void>(
      context: viewerContext,
      builder: (_) => const AlertDialog(content: Text('Viewer dialog')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Viewer dialog'), findsOneWidget);

    platform.status = const PlayUpdateStatus(
      available: true,
      availableVersionCode: 17,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Viewer dialog'), findsNothing);
    expect(find.text('Full screen viewer'), findsNothing);
    expect(find.text('Update required'), findsOneWidget);
    expect(await navigator.currentState!.maybePop(), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Update required'), findsOneWidget);
    expect(platform.saved, 17);
  });

  testWidgets('store fallback does not unlock; verified installation does', (
    tester,
  ) async {
    platform.saved = 17;
    platform.offline = true;
    await mount(tester);
    expect(find.text('Update required'), findsOneWidget);
    await tester.tap(find.byKey(const Key('required_update_button')));
    await tester.pumpAndSettle();
    expect(platform.storeLaunches, 1);
    expect(find.text('Private media library'), findsNothing);
    expect(controller.blocksApp, isTrue);

    platform.installed = 17;
    platform.offline = false;
    await controller.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Private media library'), findsOneWidget);
    expect(platform.saved, isNull);
  });

  testWidgets('update screen remains usable with large text on small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    platform.saved = 17;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: RequiredUpdateGate(controller: controller, child: child!),
        ),
        home: const Scaffold(body: Text('Private media library')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('required_update_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('required_update_button')));
    await tester.pumpAndSettle();
    expect(platform.storeLaunches, 1);
  });
}
