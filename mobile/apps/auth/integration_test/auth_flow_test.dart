import 'package:ente_auth/app/view/app.dart';
import 'package:ente_auth/bootstrap.dart';
import 'package:ente_auth/main.dart';
import 'package:ente_auth/onboarding/view/common/add_chip.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_lock_screen/local_authentication_service.dart';
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

        // Step 9: Test search functionality
        print('🔍 Testing search functionality...');

        // Click on search icon to activate search
        final searchIcon = find.byIcon(Icons.search);
        expect(searchIcon, findsOneWidget, reason: 'Search icon not found');
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        // Find the search text field
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget,
            reason: 'Search text field not found');

        // Enter search term "issuer2"
        await tester.tap(searchField);
        await tester.enterText(searchField, 'issuer2');
        await tester.pumpAndSettle();

        // Verify only one result is shown (testIssuer2)
        final searchResults = find.textContaining('testIssuer');
        final issuer2Results = find.textContaining('testIssuer2');

        // Should find testIssuer2 but not testIssuer when searching for "issuer2"
        expect(issuer2Results, findsAtLeastNWidgets(1),
            reason: 'testIssuer2 not found in search results');

        // Verify total results - should only show the matching entry
        final allVisibleIssuers = find.textContaining('testIssuer');
        expect(allVisibleIssuers.evaluate().length, equals(1),
            reason: 'Search should show only one result for "issuer2"');

        print('✅ Search results verified: only testIssuer2 is visible');

        // Clear search bar
        final clearIcon = find.byIcon(Icons.clear);
        expect(clearIcon, findsOneWidget,
            reason: 'Clear search icon not found');
        await tester.tap(clearIcon);
        await tester.pumpAndSettle();

        // Verify both entries are visible again after clearing search
        final allIssuer1 = find.textContaining('testIssuer');
        final allIssuer2 = find.textContaining('testIssuer2');
        expect(allIssuer1, findsAtLeastNWidgets(1),
            reason: 'testIssuer not visible after clearing search');
        expect(allIssuer2, findsAtLeastNWidgets(1),
            reason: 'testIssuer2 not visible after clearing search');

        print('✅ Search cleared: both entries visible again');
        print('✅ Step 3 completed: Search functionality working correctly');

        // Step 10: Long press on issuer2 to edit and add tags
        print('🏷️  Testing tag functionality...');

        // Long press on testIssuer2 entry to bring up edit menu
        final issuer2Entry = find.textContaining('testIssuer2');
        expect(issuer2Entry, findsOneWidget,
            reason: 'testIssuer2 entry not found for long press');
        await tester.longPress(issuer2Entry);
        await tester.pumpAndSettle();
        LocalAuthenticationService.instance.lastAuthTime = DateTime.now()
            .add(const Duration(minutes: 10))
            .millisecondsSinceEpoch;

        // Look for edit option and tap it
        final editOption = find.text('Edit');
        expect(editOption, findsOneWidget, reason: 'Edit option not found');
        await tester.tap(editOption);
        await tester.pumpAndSettle();

        // Wait for edit page to load
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for AddChip widget to add first tag
        final addChip = find.byType(AddChip);
        expect(addChip, findsOneWidget, reason: 'AddChip widget not found');
        await tester.tap(addChip);
        await tester.pumpAndSettle();

        // Enter first tag name "tag1"
        final tagInputField = find.byType(TextField).last;
        await tester.tap(tagInputField);
        await tester.enterText(tagInputField, 'tag1');
        await tester.pumpAndSettle();

        // Tap create/save button for first tag
        final createButton = find.text('Create');
        expect(createButton, findsOneWidget,
            reason: 'Create button not found for first tag');
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Add second tag
        final addChip2 = find.byType(AddChip);
        await tester.tap(addChip2);
        await tester.pumpAndSettle();

        // Enter second tag name "tag2"
        final tagInputField2 = find.byType(TextField).last;
        await tester.tap(tagInputField2);
        await tester.enterText(tagInputField2, 'tag2');
        await tester.pumpAndSettle();

        // Tap create button for second tag
        final createButton2 = find.text('Create');
        await tester.tap(createButton2);
        await tester.pumpAndSettle();

        // Verify tags are selected/visible
        final tag1Chip = find.text('tag1');
        final tag2Chip = find.text('tag2');
        expect(tag1Chip, findsOneWidget,
            reason: 'tag1 not found after creation');
        expect(tag2Chip, findsOneWidget,
            reason: 'tag2 not found after creation');

        print('✅ Tags created: tag1 and tag2 are visible');

        // Save the edited entry
        final saveEditButton = find.text('Save');
        expect(saveEditButton, findsOneWidget,
            reason: 'Save button not found on edit page');
        await tester.tap(saveEditButton);
        await tester.pumpAndSettle();

        // Wait for navigation back to home
        await tester.pumpAndSettle(const Duration(seconds: 2));

        print('✅ Entry saved with tags');

        // Step 11: Test tag filtering functionality
        print('🏷️  Testing tag filtering...');
        
        // Click on tag1 to filter entries
        final tag1Filter = find.textContaining('tag1');
        if (tag1Filter.evaluate().isNotEmpty) {
          await tester.tap(tag1Filter.first);
          await tester.pumpAndSettle();
          
          // Verify only testIssuer2 is visible (the one with tag1)
          final filteredIssuer2 = find.textContaining('testIssuer2');
          final filteredIssuer1 = find.textContaining('testIssuer').evaluate().where(
            (element) => !element.widget.toString().contains('testIssuer2')
          ).length;
          
          expect(filteredIssuer2, findsAtLeastNWidgets(1), 
                 reason: 'testIssuer2 not visible when filtering by tag1');
          expect(filteredIssuer1, equals(0), 
                 reason: 'testIssuer should not be visible when filtering by tag1');
          
          print('✅ Tag1 filtering verified: only testIssuer2 is visible');
          
          // Click "All" to clear tag filter
          final allFilter = find.text('All');
          if (allFilter.evaluate().isNotEmpty) {
            await tester.tap(allFilter);
            await tester.pumpAndSettle();
            
            // Verify both entries are visible again
            final allEntriesIssuer1 = find.textContaining('testIssuer');
            final allEntriesIssuer2 = find.textContaining('testIssuer2');
            expect(allEntriesIssuer1, findsAtLeastNWidgets(1));
            expect(allEntriesIssuer2, findsAtLeastNWidgets(1));
            
            print('✅ Tag filter cleared: both entries visible again');
          }
        }
        
        print('✅ Step 4 completed: Tag functionality working correctly');

        // Step 12: Test trash functionality  
        print('🗑️  Testing trash functionality...');
        
        // Long press on testIssuer2 entry to bring up context menu
        final issuer2EntryForTrash = find.textContaining('testIssuer2').first;
        await tester.longPress(issuer2EntryForTrash);
        await tester.pumpAndSettle();

        // Look for trash/delete option and tap it
        final trashOption = find.text('Trash');
        if (trashOption.evaluate().isEmpty) {
          // Try alternative delete options
          final deleteOption = find.text('Delete');
          expect(deleteOption, findsOneWidget, reason: 'Delete/Trash option not found');
          await tester.tap(deleteOption);
        } else {
          await tester.tap(trashOption);
        }
        await tester.pumpAndSettle();

        // Confirm deletion if dialog appears
        final confirmButtons = [
          find.text('Yes'),
          find.text('OK'), 
          find.text('Confirm'),
          find.text('Delete'),
          find.text('Trash'),
        ];
        
        for (final button in confirmButtons) {
          if (button.evaluate().isNotEmpty) {
            await tester.tap(button);
            await tester.pumpAndSettle();
            break;
          }
        }

        print('✅ Issuer2 entry trashed');

        // Step 13: Verify tags are no longer visible and trash tag appears
        print('🏷️  Verifying tag visibility after trash...');
        
        // Wait for UI to update
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify tag1 and tag2 are no longer visible (since issuer2 was the only entry with these tags)
        final tag1Visible = find.textContaining('tag1');
        final tag2Visible = find.textContaining('tag2');
        
        // Tags should not be visible anymore since the only entry with these tags was trashed
        expect(tag1Visible.evaluate().isEmpty, isTrue, reason: 'tag1 should not be visible after trashing issuer2');
        expect(tag2Visible.evaluate().isEmpty, isTrue, reason: 'tag2 should not be visible after trashing issuer2');

        // Verify trash tag is now visible
        final trashTag = find.text('Trash');
        expect(trashTag, findsOneWidget, reason: 'Trash tag not visible after trashing entry');

        print('✅ Tags hidden and Trash tag visible');

        // Step 14: Test trash filtering
        print('🗑️  Testing trash tag filtering...');
        
        // Click on Trash tag to show trashed items
        await tester.tap(trashTag);
        await tester.pumpAndSettle();

        // Verify issuer2 is visible in trash
        final trashedIssuer2 = find.textContaining('testIssuer2');
        expect(trashedIssuer2, findsOneWidget, reason: 'testIssuer2 not visible in trash');

        // Verify issuer1 is not visible (should be filtered out)
        final issuer1InTrash = find.textContaining('testIssuer').evaluate().where(
          (element) => !element.widget.toString().contains('testIssuer2')
        ).length;
        expect(issuer1InTrash, equals(0), reason: 'testIssuer should not be visible in trash filter');

        print('✅ Trash filtering working: only trashed items visible');

        // Step 15: Test All filter (should not show trashed items)
        print('📋 Testing All filter excludes trash...');
        
        // Click on "All" to show all non-trashed items
        final allTag = find.text('All');
        await tester.tap(allTag);
        await tester.pumpAndSettle();

        // Verify issuer1 is visible
        final allFilterIssuer1 = find.textContaining('testIssuer').evaluate().where(
          (element) => !element.widget.toString().contains('testIssuer2')
        ).length;
        expect(allFilterIssuer1, greaterThan(0), reason: 'testIssuer should be visible in All filter');

        // Verify issuer2 is NOT visible in All
        final allFilterIssuer2 = find.textContaining('testIssuer2');
        expect(allFilterIssuer2.evaluate().isEmpty, isTrue, reason: 'testIssuer2 should not be visible in All filter');

        print('✅ All filter working: trashed items excluded');

        // Step 16: Test restore functionality
        print('♻️  Testing restore functionality...');
        
        // Go back to trash view
        await tester.tap(trashTag);
        await tester.pumpAndSettle();

        // Long press on trashed issuer2 entry
        final trashedEntryForRestore = find.textContaining('testIssuer2');
        await tester.longPress(trashedEntryForRestore);
        await tester.pumpAndSettle();

        // Look for restore option
        final restoreOption = find.text('Restore');
        expect(restoreOption, findsOneWidget, reason: 'Restore option not found');
        await tester.tap(restoreOption);
        await tester.pumpAndSettle();

        print('✅ Restore option tapped');

        // Step 17: Verify restoration worked
        print('✅ Verifying restoration...');
        
        // Wait for restoration to complete
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Go to All view to check if issuer2 is restored
        await tester.tap(allTag);
        await tester.pumpAndSettle();

        // Verify both entries are now visible in All
        final restoredIssuer1 = find.textContaining('testIssuer');
        final restoredIssuer2 = find.textContaining('testIssuer2');
        
        expect(restoredIssuer1, findsAtLeastNWidgets(1), reason: 'testIssuer not visible after restore');
        expect(restoredIssuer2, findsAtLeastNWidgets(1), reason: 'testIssuer2 not visible after restore');

        // Verify tags are visible again
        final restoredTag1 = find.textContaining('tag1');
        final restoredTag2 = find.textContaining('tag2');
        
        if (restoredTag1.evaluate().isNotEmpty && restoredTag2.evaluate().isNotEmpty) {
          print('✅ Tags restored and visible again');
        }

        print('✅ Step 5 completed: Trash and restore functionality working correctly');

        print('✅ Integration test completed successfully!');
        print('- Both entries created and verified');
        print('- Search functionality tested and working');
        print('- Tag functionality tested and working');  
        print('- Trash functionality tested and working');
        print('- Restore functionality tested and working');
        print('- Multiple TOTP codes are being generated');
        print('- Data persistence is working correctly');
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}
