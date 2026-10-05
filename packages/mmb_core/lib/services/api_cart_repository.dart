import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/sse_client.dart';

class ApiCartRepository {
  ApiCartRepository(this._client, {MmbSseClient? sseClient, List<Product> Function()? productsProvider})
      : _sseClient = sseClient ?? MmbSseClient(),
        _productsProvider = productsProvider;

  final MmbApiClient _client;
  final MmbSseClient _sseClient;
  List<Product> Function()? _productsProvider;

  void setProductsProvider(List<Product> Function() provider) {
    _productsProvider = provider;
  }

  /// Helper to enrich raw cart response with catalog details if needed
  List<CartItem> _enrichItems(List<dynamic> rawList) {
    final products = _productsProvider?.call() ?? const [];
    return rawList.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final pId = (m['productId'] ?? m['id'] ?? '').toString();
      final p = products.where((prod) => prod.id == pId).firstOrNull;

      return CartItem(
        productId: pId,
        sellerId: (m['sellerId'] ?? p?.sellerId ?? '').toString(),
        name: (m['name'] ?? m['productName'] ?? p?.name ?? 'Product').toString(),
        imageUrl: (m['imageUrl'] ?? m['image'] ?? (p != null && p.imageUrls.isNotEmpty ? p.imageUrls.first : '')).toString(),
        variantLabel: (m['variantLabel'] ?? p?.variantLabel ?? '').toString(),
        unitPrice: ((m['unitPrice'] ?? m['price'] ?? p?.bulkPrice ?? 0) as num).toDouble(),
        minOrderQty: ((m['minOrderQty'] ?? p?.minOrderQty ?? 1) as num).toInt(),
        quantity: ((m['quantity'] ?? 1) as num).toInt(),
      );
    }).toList();
  }

  /// GET /api/cart
  Future<List<CartItem>> getCart({String? userId}) async {
    final query = <String, String>{};
    if (userId != null && userId.isNotEmpty) query['userId'] = userId;
    final res = await _client.get(MmbApiConfig.cart, queryParams: query);
    if (res is List) {
      return _enrichItems(res);
    }
    return const [];
  }

  /// POST /api/cart
  Future<void> addToCart(String productId, int quantity, {String? userId}) async {
    final body = {
      'productId': productId,
      'quantity': quantity,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };
    await _client.post(MmbApiConfig.cart, body: body);
  }

  /// PUT /api/cart/qty
  Future<void> updateQty(String productId, int quantity) async {
    final body = {
      'productId': productId,
      'quantity': quantity,
    };
    await _client.put(MmbApiConfig.cartQty, body: body);
  }

  /// Compatibility upsert method matching previous interface
  Future<void> upsert(String uid, CartItem item) async {
    await addToCart(item.productId, item.quantity, userId: uid);
  }

  /// Compatibility setQty method matching previous interface
  Future<void> setQty(String uid, String productId, int qty) async {
    await updateQty(productId, qty);
  }

  /// DELETE /api/cart/:productId
  Future<void> remove(String uid, String productId) async {
    await _client.delete(MmbApiConfig.cartItem(productId));
  }

  /// DELETE /api/cart (clear entire cart)
  Future<void> clearCart() async {
    await _client.delete(MmbApiConfig.cart);
  }

  /// Real-time live stream of cart items from GET /api/cart/stream?userId=<userId>
  Stream<List<CartItem>> watch(String userId) {
    late StreamController<List<CartItem>> controller;
    StreamSubscription? sseSub;

    controller = StreamController<List<CartItem>>.broadcast(
      onListen: () async {
        // Initial fetch
        try {
          final initial = await getCart(userId: userId);
          if (!controller.isClosed) controller.add(initial);
        } catch (e) {
          debugPrint('[ApiCart] Initial cart fetch failed: $e');
        }

        // Connect SSE
        sseSub = _sseClient
            .connect(MmbApiConfig.streamCart(userId), authToken: _client.authToken)
            .listen(
          (data) {
            if (controller.isClosed) return;
            if (data is List) {
              controller.add(_enrichItems(data));
            }
          },
          onError: (e) => debugPrint('[ApiCart] SSE cart error: $e'),
        );
      },
      onCancel: () => sseSub?.cancel(),
    );

    return controller.stream;
  }
}
