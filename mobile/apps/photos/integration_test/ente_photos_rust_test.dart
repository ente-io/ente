import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photos/src/rust/api/init.dart';
import 'package:photos/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await EntePhotosRust.init();
  });

  test('Can call rust function', () {
    expect(greet(name: 'Test'), equals('Hello, Test!'));
  });
}
