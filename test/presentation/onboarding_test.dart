import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_status_saver/app/theme/app_theme.dart';
import 'package:whatsapp_status_saver/application/access/access_notifier.dart';
import 'package:whatsapp_status_saver/application/access/access_state.dart';
import 'package:whatsapp_status_saver/application/providers.dart';
import 'package:whatsapp_status_saver/core/errors/app_failure.dart';
import 'package:whatsapp_status_saver/presentation/onboarding/permission_onboarding_screen.dart';

class MockAccessNotifier extends AccessNotifier {
  final AccessState initialState;
  bool requested = false;
  String? requestedPackage;

  MockAccessNotifier([this.initialState = const AccessInitial()]);

  @override
  AccessState build() => initialState;

  @override
  Future<void> requestAccess({String targetPackage = ''}) async {
    requested = true;
    requestedPackage = targetPackage;
  }

  void setState(AccessState newState) {
    state = newState;
  }
}

void main() {
  Widget buildTestable({
    required MockAccessNotifier mockNotifier,
    VoidCallback? onAccessGranted,
  }) {
    return ProviderScope(
      overrides: [accessNotifierProvider.overrideWith(() => mockNotifier)],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: PermissionOnboardingScreen(onAccessGranted: onAccessGranted),
      ),
    );
  }

  group('Phase 2E-B4: PermissionOnboardingScreen', () {
    testWidgets(
      'explains the one-time WhatsApp Media connection and requests it',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(800, 1200);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mock = MockAccessNotifier(const AccessInitial());

        await tester.pumpWidget(buildTestable(mockNotifier: mock));

        expect(
          find.text(
            'We take you straight to WhatsApp Media. You only confirm the connection once.',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('whatsapp_media_folder_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('whatsapp_media_folder_preview')),
          findsOneWidget,
        );
        expect(find.text('ONE-TIME SETUP'), findsOneWidget);
        expect(find.text('WhatsApp Media'), findsOneWidget);
        expect(find.text('Android opens this for you'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('connect_whatsapp_media_button')),
            matching: find.text('Connect WhatsApp Media'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Use this folder'), findsOneWidget);
        expect(find.textContaining('All files'), findsNothing);

        // Tapping the scoped-folder CTA triggers requestAccess().
        await tester.tap(
          find.byKey(const Key('connect_whatsapp_media_button')),
        );
        await tester.pump();
        expect(mock.requested, isTrue);
      },
    );

    testWidgets('displays loading state on CTA during AccessRequesting', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mock = MockAccessNotifier(const AccessRequesting());

      await tester.pumpWidget(buildTestable(mockNotifier: mock));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Opening WhatsApp Media…'), findsOneWidget);
      // Button should be disabled during loading
      await tester.tap(find.byType(CircularProgressIndicator));
      expect(mock.requested, isFalse);
    });

    testWidgets('displays warning banner on AccessInvalid state', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mock = MockAccessNotifier(
        const AccessInvalid(reason: 'Please select the WhatsApp media folder'),
      );

      await tester.pumpWidget(buildTestable(mockNotifier: mock));

      expect(
        find.text(
          'Your connection needs to be refreshed. Reconnect WhatsApp Media to see statuses.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays error banner on AccessFailure state', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mock = MockAccessNotifier(
        const AccessFailure(AccessNotGrantedFailure('SAF permission denied')),
      );

      await tester.pumpWidget(buildTestable(mockNotifier: mock));

      expect(
        find.text('We could not connect WhatsApp Media. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('triggers onAccessGranted callback when access is granted', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var grantedCalled = false;
      final mock = MockAccessNotifier(const AccessInitial());

      await tester.pumpWidget(
        buildTestable(
          mockNotifier: mock,
          onAccessGranted: () => grantedCalled = true,
        ),
      );

      expect(grantedCalled, isFalse);

      // State changes to granted
      mock.setState(const AccessGranted());
      await tester.pump();

      expect(grantedCalled, isTrue);
    });

    testWidgets('request uses the selected WhatsApp source', (tester) async {
      final mock = MockAccessNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [accessNotifierProvider.overrideWith(() => mock)],
          child: MaterialApp(home: PermissionOnboardingScreen()),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PermissionOnboardingScreen)),
      );
      container
          .read(selectedTargetPackageProvider.notifier)
          .selectPackage('com.whatsapp.w4b');
      await tester.tap(find.byKey(const Key('connect_whatsapp_media_button')));
      expect(mock.requestedPackage, 'com.whatsapp.w4b');
    });

    testWidgets('keeps the connect action visible on a short phone', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 520);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestable(mockNotifier: MockAccessNotifier()),
      );

      final button = find.byKey(const Key('connect_whatsapp_media_button'));
      expect(button, findsOneWidget);
      expect(
        tester.getRect(button).bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
