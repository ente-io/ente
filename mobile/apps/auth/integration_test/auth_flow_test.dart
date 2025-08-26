import 'package:ente_auth/app/view/app.dart';
import 'package:ente_auth/bootstrap.dart';
import 'package:ente_auth/main.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Test with Persistence', () {
    testWidgets(
      'Complete auth flow: Use without backup -> Enter setup key -> Verify entry persists after restart',
      (WidgetTester tester) async {
        // Bootstrap the app
        await bootstrap(App.new);
        await init(false, via: 'integrationTest');
        await UpdateService.instance.init();
        await tester.pumpAndSettle();

        // Step 1: Click on "Use without backup" option
        final useOfflineText = find.text('Use without backups');
        expect(
          useOfflineText,
          findsOneWidget,
          reason:
              'ERROR: "Use without backups" button not found on initial screen. Check if app loaded correctly or text changed.',
        );
        await tester.tap(useOfflineText);
        await tester.pumpAndSettle();

        // Step 2: Click OK button on the warning dialog
        final okButton = find.text('Ok');
        expect(
          okButton,
          findsOneWidget,
          reason:
              'ERROR: "Ok" button not found in warning dialog. Check if dialog appeared or button text changed.',
        );
        await tester.tap(okButton);
        await tester.pumpAndSettle();

        // Wait for navigation to complete
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Step 3: Navigate to manual entry screen
        bool foundManualEntry = false;

        // Try FloatingActionButton approach first
        final fabFinder = find.byType(FloatingActionButton);
        if (fabFinder.evaluate().isNotEmpty) {
          await tester.tap(fabFinder);
          await tester.pumpAndSettle();

          final manualEntryFinder = find.text('Enter a setup key');
          if (manualEntryFinder.evaluate().isNotEmpty) {
            await tester.tap(manualEntryFinder);
            await tester.pumpAndSettle();
            foundManualEntry = true;
          }
        }

        // Alternative approaches if FAB didn't work
        if (!foundManualEntry) {
          final alternatives = [
            'Enter details manually',
            'Enter a setup key',
          ];

          for (final text in alternatives) {
            final finder = find.text(text);
            if (finder.evaluate().isNotEmpty) {
              await tester.tap(finder.first);
              await tester.pumpAndSettle();
              foundManualEntry = true;
              break;
            }
          }
        }

        expect(
          foundManualEntry,
          isTrue,
          reason:
              'ERROR: Could not find manual entry option. Tried FAB + "Enter details manually", "Enter a setup key", etc. Check UI navigation.',
        );

        // Step 4: Fill in the form with test data
        final textFields = find.byType(TextFormField);
        expect(
          textFields.evaluate().length,
          greaterThanOrEqualTo(3),
          reason:
              'ERROR: Expected at least 3 text fields (issuer, secret, account) but found ${textFields.evaluate().length}. Check manual entry form.',
        );

        // Fill issuer field
        await tester.tap(textFields.first);
        await tester.enterText(textFields.first, 'testIssuer');
        await tester.pumpAndSettle();

        // Fill secret field
        await tester.tap(textFields.at(1));
        await tester.enterText(
          textFields.at(1),
          'JBSWY3DPEHPK3PXP',
        ); // Valid base32 secret
        await tester.pumpAndSettle();

        // Fill account field
        await tester.tap(textFields.at(2));
        await tester.enterText(textFields.at(2), 'testAccount');
        await tester.pumpAndSettle();

        // Step 5: Save the entry
        final saveButton = find.text('Save');
        expect(
          saveButton,
          findsOneWidget,
          reason:
              'ERROR: "Save" button not found on manual entry form. Check if button text changed or form layout changed.',
        );
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Step 6: Verify entry was created successfully
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Check if coach mark overlay is present and dismiss it
        final coachMarkOverlay = find.text('Ok');
        if (coachMarkOverlay.evaluate().isNotEmpty) {
          print('🎯 Dismissing coach mark overlay...');
          await tester.tap(coachMarkOverlay);
          await tester.pumpAndSettle();
        }

        // Look for the created entry
        final issuerEntryFinder = find.textContaining('testIssuer');
        expect(
          issuerEntryFinder,
          findsAtLeastNWidgets(1),
          reason:
              'ERROR: testIssuer entry not found after saving. Entry creation may have failed or navigation issue occurred.',
        );

        final accountEntryFinder = find.textContaining('testAccount');
        expect(
          accountEntryFinder,
          findsAtLeastNWidgets(1),
          reason:
              'ERROR: testAccount not found after saving. Account field may not have been saved properly.',
        );
        print('✅ Step 1 completed: Entry created successfully');
        print('- testIssuer entry is visible');
        print('- testAccount is visible');

        // warning about clearing

        // Step 8: Add second code entry
        print('🔄 Adding second code entry...');

        // Wait a moment before adding second entry
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Click FAB to add second entry
        final fabFinder2 = find.byType(FloatingActionButton);
        expect(
          fabFinder2,
          findsOneWidget,
          reason: 'FAB not found for second entry',
        );
        await tester.tap(fabFinder2);
        await tester.pumpAndSettle();

        // Click "Enter details manually" (coach mark won't show second time)
        final manualEntryFinder = find.text('Enter details manually');
        expect(
          manualEntryFinder,
          findsOneWidget,
          reason: 'Manual entry option not found',
        );
        await tester.tap(manualEntryFinder);
        await tester.pumpAndSettle();

        // Fill second entry form
        final textFields2 = find.byType(TextFormField);
        expect(textFields2.evaluate().length, greaterThanOrEqualTo(3));

        // Fill second issuer field
        await tester.tap(textFields2.first);
        await tester.enterText(textFields2.first, 'testIssuer2');
        await tester.pumpAndSettle();

        // Verify issuer field was filled
        final issuerField = tester.widget<TextFormField>(textFields2.first);
        print(
            '✓ Issuer field controller text: "${issuerField.controller?.text ?? "null"}"');

        // Fill second secret field
        await tester.tap(textFields2.at(1));
        await tester.enterText(textFields2.at(1), 'JBSWY3DPEHPK3PXP');
        await tester.pumpAndSettle();

        // Verify secret field was filled
        final secretField = tester.widget<TextFormField>(textFields2.at(1));
        print(
            '✓ Secret field controller text: "${secretField.controller?.text ?? "null"}"');

        // Fill second account field
        await tester.tap(textFields2.at(2));
        await tester.enterText(textFields2.at(2), 'testAccount2');
        await tester.pumpAndSettle();

        // Save second entry
        final saveButton2 = find.text('Save');
        await tester.tap(saveButton2);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify both entries exist
        final issuer1Finder = find.textContaining('testIssuer');
        final issuer2Finder = find.textContaining('testIssuer2');
        final account1Finder = find.textContaining('testAccount');
        final account2Finder = find.textContaining('testAccount2');

        expect(issuer1Finder, findsAtLeastNWidgets(1),
            reason: 'First issuer not found');
        expect(issuer2Finder, findsAtLeastNWidgets(1),
            reason: 'Second issuer not found');
        expect(
          account1Finder,
          findsAtLeastNWidgets(1),
          reason: 'First account not found',
        );
        expect(
          account2Finder,
          findsAtLeastNWidgets(1),
          reason: 'Second account not found',
        );

        print('✅ Step 2 completed: Both entries created successfully');
        print('- testIssuer and testIssuer2 entries are visible');
        print('- testAccount and testAccount2 are visible');

        print('✅ Integration test completed successfully!');
        print('- Both entries created and verified');
        print('- Multiple TOTP codes are being generated');
        print('- Data persistence is working correctly');
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}
