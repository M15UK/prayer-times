import 'dart:convert';
import 'dart:io';

/// The HTTP status code and body text of a response.
typedef HttpResult = ({int status, String body});

/// Long enough for a slow mobile connection, short enough not to hang.
const _timeout = Duration(seconds: 20);

/// Downloads [url] as text. Throws an [IOException] when offline and a
/// TimeoutException when the server is too slow.
Future<HttpResult> httpGet(Uri url) async {
  final client = HttpClient()..connectionTimeout = _timeout;
  try {
    final request = await client.getUrl(url);
    final response = await request.close().timeout(_timeout);
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_timeout);
    return (status: response.statusCode, body: body);
  } finally {
    client.close();
  }
}
