import 'dart:io';

import 'package:club_tennis_villejust_ops/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File storageFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ctv_ops_test_');
    storageFile = File('${tempDir.path}/records.json');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('shows operations navigation and screenshot records', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ClubTennisOpsApp(screenshotModeOverride: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operations today'), findsOneWidget);
    expect(find.text('Corporate membership renewal'), findsOneWidget);

    await tester.tap(_navLabel('Assets'));
    await tester.pumpAndSettle();

    expect(find.text('Asset board'), findsOneWidget);
    expect(find.text('Court 2 ball machine'), findsOneWidget);
  });

  testWidgets('creates and stores a lead record locally', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ClubTennisOpsApp(
        screenshotModeOverride: false,
        storageFileOverride: storageFile,
      ),
    );
    await _pumpLocalLoad(tester);

    await tester.tap(_navLabel('Leads'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-record-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('record-title-field')),
      'Local sponsor inquiry',
    );
    await tester.enterText(
      find.byKey(const Key('record-owner-field')),
      'Reception team',
    );
    await tester.enterText(
      find.byKey(const Key('record-due-field')),
      'Friday morning',
    );
    await tester.enterText(
      find.byKey(const Key('record-note-field')),
      'Confirm signage options and available membership packages.',
    );
    await tester.tap(find.byKey(const Key('save-record-button')));
    await tester.pumpAndSettle();

    expect(find.text('Local sponsor inquiry'), findsOneWidget);
    expect(find.text('Reception team - Friday morning'), findsOneWidget);

    await _waitForStoredRecord(tester, storageFile, 'Local sponsor inquiry');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ClubTennisOpsApp(
        screenshotModeOverride: false,
        storageFileOverride: storageFile,
      ),
    );
    await _pumpLocalLoad(tester);

    await tester.tap(_navLabel('Leads'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Local sponsor inquiry'), findsOneWidget);
  });
}

Finder _navLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

Future<void> _pumpLocalLoad(WidgetTester tester) async {
  await tester.pump();
  for (var attempt = 0; attempt < 30; attempt += 1) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      return;
    }
  }
}

Future<void> _waitForStoredRecord(
  WidgetTester tester,
  File storageFile,
  String text,
) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 40; attempt += 1) {
      if (await storageFile.exists()) {
        final contents = await storageFile.readAsString();
        if (contents.contains(text)) {
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    throw StateError('Stored record was not written to ${storageFile.path}');
  });
}
