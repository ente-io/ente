import 'package:flutter/material.dart';
import 'package:ente_strings/ente_strings.dart';

/// Example widget demonstrating how to use the ente_strings package
class ExampleStringUsage extends StatelessWidget {
  const ExampleStringUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ente Strings Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Error Message:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Example 1: Using the extension method
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.strings.networkHostLookUpErr,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Alternative usage:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Example 2: Using the traditional approach
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                StringsLocalizations.of(context).networkHostLookUpErr,
                style: const TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example main app demonstrating setup
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ente Strings Example',
      // Configure localization delegates
      localizationsDelegates: [
        ...StringsLocalizations.localizationsDelegates,
        // Add your other app-specific delegates here
      ],
      supportedLocales: StringsLocalizations.supportedLocales,
      home: const ExampleStringUsage(),
    );
  }
}

void main() {
  runApp(const ExampleApp());
}
