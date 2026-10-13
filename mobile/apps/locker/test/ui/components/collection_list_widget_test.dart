import 'dart:io';

import 'package:ente_components/ente_components.dart';
import 'package:ente_sharing/models/user.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locker/models/selected_collections.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/utils/file_icon_utils.dart';

import '../../test_utils/configuration_test_util.dart';

void main() {
  late Directory configurationDirectory;

  setUpAll(() async {
    configurationDirectory = await setupLockerConfigurationForTest(
      'collection_selection',
    );
    await Configuration.instance.setUserID(1);
  });

  tearDownAll(() async {
    clearLockerConfigurationTestHandlers();
    await configurationDirectory.delete(recursive: true);
  });

  for (final type in [CollectionType.favorites, CollectionType.folder]) {
    final name = type == CollectionType.favorites ? 'Important' : 'Documents';
    testWidgets('$name shows a check badge when selected and hides it on tap', (
      tester,
    ) async {
      final collection = Collection(
        1,
        User(id: 1, email: 'test@ente.com'),
        '',
        null,
        name,
        null,
        null,
        type,
        CollectionAttributes(),
        [],
        [],
        0,
      );
      final selectedCollections = SelectedCollections();
      addTearDown(selectedCollections.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ComponentTheme.lightTheme(app: ComponentApp.locker),
          localizationsDelegates: StringsLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: ItemListView(
              collections: [collection],
              selectedCollections: selectedCollections,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SelectionCheckBadge), findsNothing);

      await tester.longPress(find.text(name));
      await tester.pumpAndSettle();
      expect(selectedCollections.count, 1);
      expect(find.byType(SelectionCheckBadge), findsOneWidget);

      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      expect(selectedCollections.count, 0);
      expect(find.byType(SelectionCheckBadge), findsNothing);
    });
  }
}
