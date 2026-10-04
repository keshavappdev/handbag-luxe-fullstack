import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../storage_service.dart';
import 'api_constants.dart';
import 'api_exceptions.dart';

class ApiBaseHelper {
  ApiBaseHelper(this._storage);

  final StorageService _storage;

  Map<String, String> get _headers => {
    if (_storage.authToken.isNotEmpty)
      'Authorization': 'Bearer ${_storage.authToken}',
  };

  Future<dynamic> post(Uri url, Map<String, dynamic> params) async {
    try {
      final response = await http
          .post(url, body: params, headers: _headers)
          .timeout(const Duration(seconds: apiTimeoutSeconds));
      return _decode(response);
    } on SocketException {
      throw FetchDataException(
        'Cannot reach the server. Check your connection and API_BASE_URL.',
      );
    } on TimeoutException {
      throw FetchDataException('The request timed out. Please try again.');
    }
  }

  /// For endpoints that return raw HTML instead of JSON (get_invoice_html)
  /// — post() always runs the response through json.decode(), which would
  /// throw a FormatException on an HTML body, so this bypasses that and
  /// hands back the response text as-is.
  Future<String> postForHtml(Uri url, Map<String, dynamic> params) async {
    try {
      final response = await http
          .post(url, body: params, headers: _headers)
          .timeout(const Duration(seconds: apiTimeoutSeconds));
      if (response.statusCode != 200) {
        throw FetchDataException(
          'Error occurred while communicating with server: ${response.statusCode}',
        );
      }
      return response.body;
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Something went wrong, try again later');
    }
  }

  /// For endpoints that accept file uploads (e.g. send_message's
  /// attachments[]) — a plain form-encoded post() can't carry files, so
  /// this builds a proper multipart/form-data request instead. [files]
  /// keys become the field name (send_message expects repeated
  /// attachments[] entries, so pass that as the key for each file).
  Future<dynamic> postMultipart(
    Uri url,
    Map<String, String> fields,
    List<MapEntry<String, File>> files,
  ) async {
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(_headers)
        ..fields.addAll(fields);
      for (final entry in files) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }
      final streamed = await request.send().timeout(
        const Duration(seconds: apiTimeoutSeconds),
      );
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Something went wrong, try again later');
    }
  }

  Future<dynamic> get(Uri url) async {
    try {
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: apiTimeoutSeconds));
      return _decode(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Something went wrong, try again later');
    }
  }

  dynamic _decode(http.Response response) {
    dynamic body;
    try {
      body = json.decode(response.body);
    } catch (_) {
      throw FetchDataException('The server returned an invalid response.');
    }
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        !(body is Map && body['error'] == true))
      return body;
    final message = body is Map
        ? '${body['message'] ?? 'Request failed'}'
        : 'Request failed';
    if (response.statusCode == 401) throw UnauthorisedException(message);
    throw FetchDataException(message);
  }
}
