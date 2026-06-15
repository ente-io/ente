import 'package:http/http.dart' as http;

/// JSON request headers.
const jsonHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

/// Throws when HTTP response status is not successful.
void ensureOk(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) return;
  throw http.ClientException(
    'HTTP ${response.statusCode}: ${response.body}',
    response.request?.url,
  );
}
