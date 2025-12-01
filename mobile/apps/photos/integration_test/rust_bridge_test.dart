import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photos/src/rust/api/urls.dart';
import 'package:photos/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await RustLib.init();
  });

  test('file_download_url integration smoke test', () {
    final url =
        fileDownloadUrl(apiBaseUrl: 'https://api.ente.io', fileId: 12345);
    expect(url, equals('https://files.ente.io/?fileID=12345'));
  });
}
