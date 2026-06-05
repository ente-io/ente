import 'package:ente_lock_screen/ui/app_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('updates theme mode after startup', (tester) async {
    await tester.pumpWidget(
      AppLock(
        builder: (_) => Builder(
          builder: (context) => Column(
            children: [
              Text(Theme.of(context).brightness.name),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AppLock.of(context)!.setThemeMode(ThemeMode.light),
                child: const Text('Use light'),
              ),
            ],
          ),
        ),
        lockScreen: const SizedBox.shrink(),
        enabled: false,
        savedThemeMode: ThemeMode.dark,
        lightTheme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[],
        localeListResolutionCallback: (_, supportedLocales) =>
            supportedLocales.first,
      ),
    );

    expect(find.text('dark'), findsOneWidget);

    await tester.tap(find.text('Use light'));
    await tester.pumpAndSettle();

    expect(find.text('light'), findsOneWidget);
  });
}
