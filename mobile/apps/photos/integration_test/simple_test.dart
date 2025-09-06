import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import "package:photos/src/rust/api/simple.dart";
import 'package:photos/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('Can call rust function', (WidgetTester tester) async {
    final testString = greet(name: "Tom");
    expect(testString.contains('Tom'), true);
  });
}
