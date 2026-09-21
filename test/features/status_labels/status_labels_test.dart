import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_status_saver/application/providers.dart';
import 'package:whatsapp_status_saver/application/statuses/status_list_notifier.dart';
import 'package:whatsapp_status_saver/application/statuses/status_list_state.dart';
import 'package:whatsapp_status_saver/core/constants/app_constants.dart';
import 'package:whatsapp_status_saver/domain/entities/status_item.dart';
import 'package:whatsapp_status_saver/features/status_labels/application/status_label_controller.dart';
import 'package:whatsapp_status_saver/features/status_labels/data/status_label_repository.dart';
import 'package:whatsapp_status_saver/features/status_labels/presentation/status_contact_label.dart';
import 'package:whatsapp_status_saver/presentation/moments/moments_screen.dart';

// The fake allows tests to change storage failures between user actions.
// ignore: must_be_immutable
class MemoryPreferences extends Fake implements SharedPreferencesAsync {
  final values = <String, String>{};
  bool failWrites = false;
  bool failReads = false;

  @override
  Future<String?> getString(String key) async {
    if (failReads) throw StateError('Test read failure');
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) throw StateError('Test write failure');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (failWrites) throw StateError('Test remove failure');
    values.remove(key);
  }
}

class SourceStatusList extends StatusListNotifier {
  @override
  StatusListState build() {
    final business =
        ref.watch(selectedTargetPackageProvider) ==
        AppConstants.whatsappBusinessPackage;
    return StatusListSuccess(
      items: [
        for (final video in [false, true])
          StatusItem(
            id: '${business ? 'business' : 'standard'}-${video ? 'video' : 'photo'}',
            displayName: 'same-name.${video ? 'mp4' : 'jpg'}',
            mimeType: video ? 'video/mp4' : 'image/jpeg',
            sizeBytes: 100,
            lastModified: DateTime.now(),
            isVideo: video,
          ),
      ],
    );
  }
}

void main() {
  late MemoryPreferences preferences;
  late StatusLabelRepository repository;

  setUp(() {
    preferences = MemoryPreferences();
    repository = StatusLabelRepository(preferences: preferences);
  });

  Widget app({String id = 'photo', double textScale = 1}) {
    return ProviderScope(
      overrides: [statusLabelRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: SizedBox(
                width: 120,
                child: StatusContactLabel(statusId: id),
              ),
            ),
          ),
        ),
      ),
    );
  }

  test(
    'labels persist across repository instances and preserve phone formatting',
    () async {
      await repository.write('photo', '  +92 300 123 4567  ');
      final reopened = StatusLabelRepository(preferences: preferences);
      expect(await reopened.read('photo'), '+92 300 123 4567');
      expect(await reopened.read('unlabeled'), isNull);
    },
  );

  test(
    'removing a label preserves other statuses and app preferences',
    () async {
      preferences.values['theme_mode'] = 'dark';
      await repository.write('standard-photo', 'Ayesha');
      await repository.write('business-photo', 'Shop');
      await repository.write('standard-photo', '   ');
      expect(await repository.read('standard-photo'), isNull);
      expect(await repository.read('business-photo'), 'Shop');
      expect(preferences.values['theme_mode'], 'dark');
    },
  );

  test(
    'controller preserves the last label when saving fails and can retry',
    () async {
      await repository.write('photo', 'Original');
      final container = ProviderContainer(
        overrides: [
          statusLabelRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      expect(
        await container.read(statusLabelProvider('photo').future),
        'Original',
      );
      final controller = container.read(statusLabelProvider('photo').notifier);
      preferences.failWrites = true;
      expect(await controller.save('Changed'), isFalse);
      expect(
        container.read(statusLabelProvider('photo')).requireValue,
        'Original',
      );
      preferences.failWrites = false;
      expect(await controller.save(' Changed '), isTrue);
      expect(
        container.read(statusLabelProvider('photo')).requireValue,
        'Changed',
      );
      expect(await repository.read('photo'), 'Changed');
    },
  );

  testWidgets('add, edit, and remove a name or phone number', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add name / number'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Sender details are not available'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Ayesha');
    await tester.tap(find.text('Save label'));
    await tester.pumpAndSettle();
    expect(find.text('Ayesha'), findsOneWidget);
    expect(await repository.read('photo'), 'Ayesha');

    await tester.tap(find.text('Ayesha'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '+92 300 123 4567');
    await tester.tap(find.text('Save label'));
    await tester.pumpAndSettle();
    expect(find.text('+92 300 123 4567'), findsOneWidget);

    await tester.tap(find.text('+92 300 123 4567'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove label'));
    await tester.pumpAndSettle();
    expect(find.text('Add name / number'), findsOneWidget);
    expect(await repository.read('photo'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed save keeps the editor and supports retry', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add name / number'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ayesha');
    preferences.failWrites = true;
    await tester.tap(find.text('Save label'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save this label. Please try again.'),
      findsOneWidget,
    );
    expect(await repository.read('photo'), isNull);
    preferences.failWrites = false;
    await tester.tap(find.text('Save label'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Ayesha'), findsOneWidget);
  });

  testWidgets('failed label reads offer a working retry', (tester) async {
    await repository.write('photo', 'Ayesha');
    preferences.failReads = true;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Retry label'), findsOneWidget);
    preferences.failReads = false;
    await tester.tap(find.text('Retry label'));
    await tester.pumpAndSettle();
    expect(find.text('Ayesha'), findsOneWidget);
  });

  testWidgets(
    'long labels fit narrow cards with large text and remain accessible',
    (tester) async {
      const label = 'A long contact name that needs more space than this card';
      await repository.write('photo', label);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(textScale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel('Name or number you added: $label. Edit'),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(48),
      );
      semantics.dispose();
    },
  );

  testWidgets('photo and video labels stay separate across WhatsApp sources', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await repository.write('standard-photo', 'Ayesha photo');
    await repository.write('standard-video', 'Ayesha video');
    await repository.write('business-photo', 'Shop photo');
    await repository.write('business-video', 'Shop video');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statusLabelRepositoryProvider.overrideWithValue(repository),
          statusListNotifierProvider.overrideWith(SourceStatusList.new),
        ],
        child: const MaterialApp(home: MomentsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ayesha photo'), findsOneWidget);
    expect(find.text('Ayesha video'), findsOneWidget);
    expect(find.text('Photos (1)'), findsOneWidget);
    expect(find.text('Videos (1)'), findsOneWidget);
    await tester.tap(find.text('WA Business'));
    await tester.pumpAndSettle();
    expect(find.text('Shop photo'), findsOneWidget);
    expect(find.text('Shop video'), findsOneWidget);
    expect(find.text('Ayesha photo'), findsNothing);
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.text('Ayesha photo'), findsOneWidget);
    expect(find.text('Shop photo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
