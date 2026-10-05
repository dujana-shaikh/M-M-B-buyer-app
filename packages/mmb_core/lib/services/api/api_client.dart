import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  const ApiException({required this.statusCode, required this.message, this.details});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class MmbApiClient {
  MmbApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _authToken;

  String? get authToken => _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
    debugPrint('[MmbApiClient] Auth token set: ${token != null ? "present" : "null"}');
  }

  void clearAuthToken() {
    _authToken = null;
    debugPrint('[MmbApiClient] Auth token cleared');
  }

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<dynamic> get(String url, {Map<String, String>? queryParams, Map<String, String>? headers}) async {
    Uri uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...queryParams});
    }

    try {
      final res = await _client.get(uri, headers: _buildHeaders(headers));
      return _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Network error: $e');
    }
  }

  Future<dynamic> post(String url, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    try {
      final res = await _client.post(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Network error: $e');
    }
  }

  Future<dynamic> put(String url, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    try {
      final res = await _client.put(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Network error: $e');
    }
  }

  Future<dynamic> delete(String url, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    try {
      final res = await _client.delete(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response res) {
    dynamic decoded;
    if (res.body.isNotEmpty) {
      try {
        decoded = jsonDecode(res.body);
      } catch (_) {
        decoded = res.body;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    String message = 'Request failed with status: ${res.statusCode}';
    if (decoded is Map && decoded['message'] != null) {
      message = decoded['message'].toString();
    } else if (decoded is Map && decoded['error'] != null) {
      message = decoded['error'].toString();
    } else if (decoded is String && decoded.isNotEmpty) {
      message = decoded;
    }

    throw ApiException(statusCode: res.statusCode, message: message, details: decoded);
  }

  void close() {
    _client.close();
  }
}
