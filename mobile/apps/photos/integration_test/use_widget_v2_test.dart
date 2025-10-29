import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/main.dart' as app;
import 'package:photos/services/album_home_widget_service.dart';
import 'package:photos/services/home_widget_service.dart';

void main() {
  group('useWidgetV2 widget capture test', () {
    final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

    testWidgets('captures 1024px album widget images', (tester) async {
      tester.testTextInput.register();

      await runZonedGuarded(
        () async {
          WidgetsFlutterBinding.ensureInitialized();
          FlutterError.onError = (FlutterErrorDetails errorDetails) {
            FlutterError.dumpErrorToConsole(errorDetails);
          };

          app.main();

          await tester.pumpAndSettle(const Duration(seconds: 1));

          await _dismissUpdateAppDialog(tester);

          final signInButton = find.byKey(const ValueKey('signInButton'));
          final shouldLogin = tester.any(signInButton);

          if (shouldLogin) {
            await tester.tap(signInButton);
            await tester.pumpAndSettle();

            final emailInputField = find.byType(TextFormField);
            final logInButton = find.byKey(const ValueKey('logInButton'));

            await tester.enterText(emailInputField, '*enter email here*');
            await tester.pumpAndSettle(const Duration(seconds: 1));
            await tester.tap(logInButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            final passwordInputField =
                find.byKey(const ValueKey('passwordInputField'));
            final verifyPasswordButton =
                find.byKey(const ValueKey('verifyPasswordButton'));

            await tester.enterText(
              passwordInputField,
              '*enter password here*',
            );
            await tester.pumpAndSettle(const Duration(seconds: 1));
            await tester.tap(verifyPasswordButton);
            await tester.pumpAndSettle();

            await tester.pumpAndSettle(const Duration(seconds: 1));
            await _dismissUpdateAppDialog(tester);

            final grantPermissionButton =
                find.byKey(const ValueKey('grantPermissionButton'));
            if (tester.any(grantPermissionButton)) {
              await tester.tap(grantPermissionButton);
              await tester.pumpAndSettle(const Duration(seconds: 1));
              await tester.pumpAndSettle(const Duration(seconds: 3));
            }

            final skipBackupButton =
                find.byKey(const ValueKey('skipBackupButton'));
            if (tester.any(skipBackupButton)) {
              await tester.tap(skipBackupButton);
              await tester.pumpAndSettle(const Duration(seconds: 2));
            }
          }

          await tester.pumpAndSettle(const Duration(seconds: 2));

          await tester.runAsync(() async {
            await AlbumHomeWidgetService.instance.setAlbumsLastHash('');
            await AlbumHomeWidgetService.instance.initAlbumHomeWidget(false);
          });

          await tester.pumpAndSettle(const Duration(seconds: 2));

          final failures = await tester.runAsync(() async {
            final widgetDir = await _resolveWidgetDirectory();
            final imageSizes = await _collectWidgetImageSizes(widgetDir);
            if (imageSizes.isEmpty) {
              return <String>['No widget images were generated at $widgetDir'];
            }
            final failedEntries = imageSizes.entries.where(
              (entry) =>
                  entry.value.width != 1024 || entry.value.height != 1024,
            );
            return failedEntries
                .map(
                  (entry) =>
                      '${entry.key}: ${entry.value.width.toInt()}x${entry.value.height.toInt()}',
                )
                .toList();
          });

          if (failures.isNotEmpty) {
            final buffer = StringBuffer()
              ..writeln('Found widget images with unexpected dimensions:');
            for (final failure in failures) {
              buffer.writeln('- $failure');
            }
            fail(buffer.toString());
          } else {
            debugPrint('All album widget captures are 1024x1024.');
          }
        },
        (error, stack) {
          Logger('use_widget_v2_test').info(error, stack);
        },
      );
    });
  });
}

Future<void> _dismissUpdateAppDialog(WidgetTester tester) async {
  await tester.tapAt(const Offset(0, 0));
  await tester.pumpAndSettle();
}

Future<String> _resolveWidgetDirectory() async {
  final basePath = await _resolveWidgetBasePath();
  return p.join(basePath, HomeWidgetService.WIDGET_DIRECTORY);
}

Future<String> _resolveWidgetBasePath() async {
  if (Platform.isIOS) {
    final provider = PathProviderFoundation();
    final containerPath = await provider.getContainerPath(
      appGroupIdentifier: iOSGroupIDMemory,
    );
    if (containerPath == null) {
      throw StateError('Failed to resolve iOS widget container path');
    }
    return containerPath;
  }
  final supportDirectory = await getApplicationSupportDirectory();
  return supportDirectory.path;
}

Future<Map<String, Size>> _collectWidgetImageSizes(String widgetDir) async {
  final directory = Directory(widgetDir);
  if (!await directory.exists()) {
    return {};
  }
  final result = <String, Size>{};
  await for (final entity in directory.list()) {
    if (entity is! File || !entity.path.endsWith('.png')) {
      continue;
    }
    final bytes = await entity.readAsBytes();
    final image = await _decodeImageFromList(bytes);
    final size = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    result[p.basename(entity.path)] = size;
    image.dispose();
  }
  return result;
}

Future<ui.Image> _decodeImageFromList(List<int> bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, (image) => completer.complete(image));
  return completer.future;
}
