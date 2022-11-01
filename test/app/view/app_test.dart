import "package:ente_auth/app/app.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("App", () {
    testWidgets("renders CounterPage", (tester) async {
      await tester.pumpWidget(const App());
      // expect(find.byType(CounterPage), findsOneWidget);
    });
  });
}
