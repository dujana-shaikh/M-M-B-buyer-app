import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MmbSseClient {
  MmbSseClient();

  /// Creates a resilient broadcast Stream from an SSE endpoint.
  /// Automatically reconnects on disconnection or error.
  Stream<dynamic> connect(
    String url, {
    String? authToken,
    Map<String, String>? headers,
  }) {
    late StreamController<dynamic> controller;
    bool isClosed = false;
    http.Client? activeClient;

    Future<void> listenLoop() async {
      int backoffMs = 1000;
      while (!isClosed && !controller.isClosed) {
        try {
          final uri = Uri.parse(url);
          final request = http.Request('GET', uri);
          request.headers['Accept'] = 'text/event-stream';
          request.headers['Cache-Control'] = 'no-cache';
          if (authToken != null && authToken.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $authToken';
          }
          if (headers != null) {
            request.headers.addAll(headers);
          }

          activeClient = http.Client();
          final response = await activeClient!.send(request);

          if (response.statusCode != 200) {
            throw Exception('SSE connection failed with status: ${response.statusCode}');
          }

          // Reset backoff on successful connection
          backoffMs = 1000;

          final stream = response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter());

          final dataBuffer = StringBuffer();

          await for (final line in stream) {
            if (isClosed || controller.isClosed) break;

            if (line.isEmpty) {
              // End of an event
              final dataStr = dataBuffer.toString().trim();
              dataBuffer.clear();
              if (dataStr.isNotEmpty) {
                try {
                  final decoded = jsonDecode(dataStr);
                  if (!controller.isClosed) {
                    controller.add(decoded);
                  }
                } catch (e) {
                  // Fallback raw string if not JSON
                  if (!controller.isClosed) {
                    controller.add(dataStr);
                  }
                }
              }
            } else if (line.startsWith('data:')) {
              final payload = line.substring(5).trim();
              if (dataBuffer.isNotEmpty) dataBuffer.write('\n');
              dataBuffer.write(payload);
            }
          }
        } catch (e) {
          if (!isClosed && !controller.isClosed) {
            debugPrint('[SSE] Disconnected from $url ($e). Reconnecting in ${backoffMs}ms...');
          }
        } finally {
          activeClient?.close();
        }

        if (!isClosed && !controller.isClosed) {
          await Future.delayed(Duration(milliseconds: backoffMs));
          backoffMs = (backoffMs * 2).clamp(1000, 15000);
        }
      }
    }

    controller = StreamController<dynamic>.broadcast(
      onListen: () {
        listenLoop();
      },
      onCancel: () {
        isClosed = true;
        activeClient?.close();
      },
    );

    return controller.stream;
  }
}
