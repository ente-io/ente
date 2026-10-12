import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ente_components/ente_components.dart';
import 'package:ente_crypto_api/ente_crypto_api.dart';
import 'package:ente_network/network.dart';
import 'package:ente_sharing/models/user.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locker/services/collections/collections_api_client.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/collections/models/public_url.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/services/db/locker_db.dart';
import 'package:locker/ui/sharing/manage_links_widget.dart';
import 'package:locker/ui/sharing/pickers/device_limit_picker_page.dart';
import 'package:locker/ui/sharing/pickers/link_expiry_picker_page.dart';
import 'package:locker/ui/sharing/share_collection_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../test_utils/configuration_test_util.dart';

void main() {
  late Directory testRoot;
  late Collection collection;
  final dio = Dio();
  final originalNetwork = Network.instance;

  setUpAll(() {
    Network.instance = _TestNetwork(dio);
    registerCryptoApi(_TestCryptoApi());
  });

  tearDownAll(() => Network.instance = originalNetwork);

  setUp(() async {
    testRoot = await setupLockerConfigurationForTest('link_settings');
    await Configuration.instance.setUserID(1);
    await Configuration.instance.setKey('AQ==');
    collection = Collection(
      1,
      User(id: 1, email: 'owner@example.com'),
      'AQ==',
      'AQ==',
      'Documents',
      null,
      null,
      CollectionType.folder,
      CollectionAttributes(),
      [],
      [
        PublicURL(
          url: 'https://example.com/link',
          deviceLimit: 0,
          validTill: 0,
        ),
      ],
      0,
    );
    CollectionService.instance.updateCollectionCache(collection);
  });

  tearDown(() async {
    await LockerDB.instance.close();
    CollectionService.instance.clearCache();
    dio.interceptors.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.tekartik.sqflite'),
          null,
        );
    clearLockerConfigurationTestHandlers();
    await testRoot.delete(recursive: true);
  });

  Future<void> showPage(WidgetTester tester, {Widget? page}) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ComponentTheme.lightTheme(app: ComponentApp.locker),
        localizationsDelegates: StringsLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: page ?? ManageSharedLinkWidget(collection: collection),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('link actions precede access settings and removal', (
    tester,
  ) async {
    await showPage(tester);

    expect(find.text('Link settings'), findsWidgets);
    const labels = [
      'Copy link',
      'Send link',
      'Anyone with the link can open the collection without an Ente account.',
      'Link expiry',
      'Password',
      'Device limit',
      'Remove link',
    ];
    for (var index = 0; index < labels.length - 1; index++) {
      expect(
        tester.getTopLeft(find.text(labels[index])).dy,
        lessThan(tester.getTopLeft(find.text(labels[index + 1])).dy),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('expired links hide sharing and retain access settings', (
    tester,
  ) async {
    collection.publicURLs.first.validTill = 1;
    await showPage(tester);

    expect(find.text('Copy link'), findsNothing);
    expect(find.text('Send link'), findsNothing);
    expect(
      find.text(
        'Anyone with the link can open the collection without an Ente account.',
      ),
      findsNothing,
    );
    expect(find.text('Link has expired'), findsOneWidget);
    expect(find.text('Link expiry'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Device limit'), findsOneWidget);
    expect(find.text('Remove link'), findsOneWidget);
  });

  testWidgets('copy uses the public URL with its collection key', (
    tester,
  ) async {
    String? copiedText;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await showPage(tester);
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(copiedText, 'https://example.com/link#2');
  });

  testWidgets('send anchors the share sheet to its row', (tester) async {
    Map<dynamic, dynamic>? shareArguments;
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      shareArguments = call.arguments as Map;
      return 'test';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await showPage(tester);
    final row = find.widgetWithText(MenuComponent, 'Send link');
    final bounds = tester.getRect(row);
    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();

    expect(shareArguments?['text'], 'https://example.com/link#2');
    expect(shareArguments?['originX'], bounds.left);
    expect(shareArguments?['originY'], bounds.top);
    expect(shareArguments?['originWidth'], bounds.width);
    expect(shareArguments?['originHeight'], bounds.height);
  });

  testWidgets('expiry and device limit still open their pickers and refresh', (
    tester,
  ) async {
    await showPage(tester);
    await tester.tap(find.text('Link expiry'));
    await tester.pumpAndSettle();
    expect(find.byType(LinkExpiryPickerPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(LinkExpiryPickerPage))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Device limit'));
    await tester.pumpAndSettle();
    expect(find.byType(DeviceLimitPickerPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DeviceLimitPickerPage),
        matching: find.text('No limit'),
      ),
      findsOneWidget,
    );
    collection.publicURLs.first.deviceLimit = 7;
    Navigator.of(tester.element(find.byType(DeviceLimitPickerPage))).pop();
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('cancelling password setup leaves the link unlocked', (
    tester,
  ) async {
    await showPage(tester);
    await tester.tap(find.byType(ToggleSwitchComponent));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Set a password'), findsOneWidget);
    Navigator.of(tester.element(find.byType(TextField))).pop();
    await tester.pumpAndSettle();
    expect(collection.publicURLs.first.passwordEnabled, isFalse);
  });

  testWidgets('new links open settings before sharing and refresh on return', (
    tester,
  ) async {
    collection.publicURLs.clear();
    final originalDatabaseFactory = databaseFactoryOrNull;
    databaseFactory = databaseFactorySqflitePlugin;
    addTearDown(() => databaseFactory = originalDatabaseFactory);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.tekartik.sqflite'),
      (call) async {
        switch (call.method) {
          case 'openDatabase':
            return {'id': 1};
          case 'query':
            final sql = (call.arguments as Map)['sql'] as String;
            return sql.contains('user_version')
                ? [
                    {'user_version': 2},
                  ]
                : <Map<String, Object?>>[];
          case 'batch':
            final operations = (call.arguments as Map)['operations'] as List;
            return [
              for (final _ in operations) {'result': 1},
            ];
          default:
            return null;
        }
      },
    );
    await tester.runAsync(() async {
      await LockerDB.instance.init();
      await CollectionApiClient.instance.init();
      await CollectionService.instance.init(
        await SharedPreferences.getInstance(),
      );
    });
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: options.path == '/collections/share-url'
                  ? {
                      'result': {
                        'url': 'https://example.com/new-link',
                        'deviceLimit': 0,
                        'validTill': 0,
                      },
                    }
                  : {'collections': []},
            ),
          );
        },
      ),
    );

    await showPage(tester, page: ShareCollectionSheet(collection: collection));
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();

    expect(find.byType(ManageSharedLinkWidget), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(collection.publicURLs.single.url, 'https://example.com/new-link');
    Navigator.of(tester.element(find.byType(ManageSharedLinkWidget))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Link settings'), findsOneWidget);
    expect(find.text('Link'), findsNothing);
  });

  testWidgets('existing collection links open Link settings from sharing', (
    tester,
  ) async {
    await showPage(tester, page: ShareCollectionSheet(collection: collection));
    expect(find.text('Manage link'), findsNothing);
    await tester.tap(find.text('Link settings'));
    await tester.pumpAndSettle();
    expect(find.byType(ManageSharedLinkWidget), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
  });

  testWidgets('failed creation stays in the sharing sheet', (tester) async {
    collection.publicURLs.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );
    await showPage(tester, page: ShareCollectionSheet(collection: collection));
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(BottomSheetComponent).last)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(ManageSharedLinkWidget), findsNothing);
    expect(find.byType(ShareCollectionSheet), findsOneWidget);
    expect(collection.publicURLs, isEmpty);
  });
}

class _TestNetwork implements Network {
  _TestNetwork(this.enteDio);

  @override
  final Dio enteDio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestCryptoApi implements CryptoApi {
  @override
  Uint8List base642bin(String value) => base64Decode(value);

  @override
  String bin2base64(Uint8List value, {bool urlSafe = false}) =>
      base64Encode(value);

  @override
  Uint8List decryptSync(Uint8List cipher, Uint8List key, Uint8List nonce) =>
      Uint8List.fromList([1]);

  @override
  EncryptionResult encryptSync(Uint8List source, Uint8List key) =>
      EncryptionResult(encryptedData: source, nonce: Uint8List.fromList([0]));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
