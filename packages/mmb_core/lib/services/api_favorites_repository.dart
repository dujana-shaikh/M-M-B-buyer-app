import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/sse_client.dart';

class ApiFavoritesRepository {
  ApiFavoritesRepository(this._client, {MmbSseClient? sseClient})
      : _sseClient = sseClient ?? MmbSseClient();

  final MmbApiClient _client;
  final MmbSseClient _sseClient;

  /// GET /api/favorites
  Future<Set<String>> getFavoriteIds({String? userId}) async {
    final query = <String, String>{};
    if (userId != null && userId.isNotEmpty) query['userId'] = userId;
    final res = await _client.get(MmbApiConfig.favorites, queryParams: query);
    if (res is Map && res['favoriteIds'] is List) {
      return Set<String>.from((res['favoriteIds'] as List).map((e) => e.toString()));
    } else if (res is List) {
      return Set<String>.from(res.map((e) => e.toString()));
    }
    return const {};
  }

  /// POST /api/favorites/toggle
  Future<bool> toggleFavorite(String productId) async {
    final res = await _client.post(MmbApiConfig.favoritesToggle, body: {'productId': productId});
    if (res is Map && res['isFavorite'] is bool) {
      return res['isFavorite'] as bool;
    }
    return true;
  }

  /// Compatibility toggle method matching previous interface
  Future<void> toggle(String uid, String productId, bool currentlyFav) async {
    await toggleFavorite(productId);
  }

  /// Real-time live stream of favorite product IDs from GET /api/favorites/stream?userId=<userId>
  Stream<Set<String>> watchIds(String userId) {
    late StreamController<Set<String>> controller;
    StreamSubscription? sseSub;

    controller = StreamController<Set<String>>.broadcast(
      onListen: () async {
        // Initial fetch
        try {
          final initial = await getFavoriteIds(userId: userId);
          if (!controller.isClosed) controller.add(initial);
        } catch (e) {
          debugPrint('[ApiFavorites] Initial fetch failed: $e');
        }

        // Connect SSE
        sseSub = _sseClient
            .connect(MmbApiConfig.streamFavorites(userId), authToken: _client.authToken)
            .listen(
          (data) {
            if (controller.isClosed) return;
            if (data is Map && data['favoriteIds'] is List) {
              controller.add(Set<String>.from((data['favoriteIds'] as List).map((e) => e.toString())));
            } else if (data is List) {
              controller.add(Set<String>.from(data.map((e) => e.toString())));
            }
          },
          onError: (e) => debugPrint('[ApiFavorites] SSE favorites error: $e'),
        );
      },
      onCancel: () => sseSub?.cancel(),
    );

    return controller.stream;
  }
}
