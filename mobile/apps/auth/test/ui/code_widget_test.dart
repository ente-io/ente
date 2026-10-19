import 'dart:io';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/store/code_display_store.dart';
import 'package:ente_auth/ui/code_widget.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);
const _toastChannel = MethodChannel('PonnamKarthik/fluttertoast');
final _nextCodeButton = find.bySemanticsIdentifier('auth_next_code_button');

void main() {
  final copied = <String>[];
  final toasts = <String>[];

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final root = await Directory.systemTemp.createTemp('auth_code_widget_');
    messenger.setMockMethodCallHandler(
      _pathProviderChannel,
      (_) async => root.path,
    );
    messenger.setMockMethodCallHandler(_secureStorageChannel, (_) async {
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(_toastChannel, (call) async {
      if (call.method == 'showToast') {
        toasts.add((call.arguments as Map)['msg'] as String);
      }
      return true;
    });
    SharedPreferences.setMockInitialValues({});
    await Configuration.instance.init([]);
    await PreferenceService.instance.init();
  });

  setUp(() {
    copied.clear();
    toasts.clear();
  });
  tearDown(CodeDisplayStore.instance.clearSelection);

  testWidgets('next code button copies the next code', (tester) async {
    final semantics = tester.ensureSemantics();
    final code = _code();
    await tester.pumpWidget(_app(code));

    expect(
      tester.getSemantics(_nextCodeButton),
      isSemantics(isButton: true, hasTapAction: true),
    );

    final nextCodes = {getNextTotp(code)};
    await tester.tap(_nextCodeButton);
    await tester.pump();
    nextCodes.add(getNextTotp(code));

    expect(copied, hasLength(1));
    expect(nextCodes, contains(copied.single));
    expect(toasts, ['Copied next code to clipboard']);
    semantics.dispose();
  });

  testWidgets('next code button lets taps select the card in selection mode', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final code = _code();
    CodeDisplayStore.instance.toggleSelection(code.selectionKey);
    await tester.pumpWidget(_app(code));

    await tester.tap(_nextCodeButton, warnIfMissed: false);
    await tester.pump();

    expect(copied, isEmpty);
    expect(toasts, isEmpty);
    expect(CodeDisplayStore.instance.selectedCodeIds.value, isEmpty);
    semantics.dispose();
  });
}

Code _code() {
  return Code.fromAccountAndSecret(
    Type.totp,
    'person@example.com',
    'Ente',
    'JBSWY3DPEHPK3PXP',
    null,
    6,
  );
}

Widget _app(Code code) {
  return MaterialApp(
    theme: lightThemeData,
    localizationsDelegates: StringsLocalizations.localizationsDelegates,
    supportedLocales: StringsLocalizations.supportedLocales,
    home: Scaffold(body: CodeWidget(code, isCompactMode: false)),
  );
}
