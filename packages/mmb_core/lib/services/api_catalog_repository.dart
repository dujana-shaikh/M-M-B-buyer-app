import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/categories.dart';
import '../models/banner_item.dart';
import '../models/product.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/sse_client.dart';

class ApiCatalogRepository {
  ApiCatalogRepository(this._client, {MmbSseClient? sseClient})
      : _sseClient = sseClient ?? MmbSseClient();

  final MmbApiClient _client;
  final MmbSseClient _sseClient;

  // ==================== PRODUCTS ====================

  /// GET /api/products?category=...&status=...&sellerId=...
  Future<List<Product>> getProducts({
    String? category,
    String? status,
    String? sellerId,
  }) async {
    final query = <String, String>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (sellerId != null && sellerId.isNotEmpty) query['sellerId'] = sellerId;

    final res = await _client.get(MmbApiConfig.products, queryParams: query);
    if (res is List) {
      return res
          .map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const [];
  }

  /// GET /api/products/:id
  Future<Product> getProduct(String id) async {
    final res = await _client.get(MmbApiConfig.product(id));
    return Product.fromMap(Map<String, dynamic>.from(res as Map));
  }

  /// POST /api/products (Single)
  Future<Product> createProduct(Product product) async {
    final res = await _client.post(MmbApiConfig.products, body: product.toJson(isCreate: true));
    return Product.fromMap(Map<String, dynamic>.from(res as Map));
  }

  /// POST /api/products (Batch)
  Future<List<Product>> createProductsBatch(List<Product> products) async {
    final body = products.map((p) => p.toJson(isCreate: true)).toList();
    final res = await _client.post(MmbApiConfig.products, body: body);
    if (res is List) {
      return res.map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    }
    return const [];
  }

  /// PUT /api/products/:id
  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    final res = await _client.put(MmbApiConfig.product(id), body: data);
    return Product.fromMap(Map<String, dynamic>.from(res as Map));
  }

  /// DELETE /api/products/:id
  Future<void> deleteProduct(String id) async {
    await _client.delete(MmbApiConfig.product(id));
  }

  // ==================== CATEGORIES & BANNERS ====================

  /// GET /api/catalog/categories
  Future<List<String>> getCategories() async {
    try {
      final res = await _client.get(MmbApiConfig.categories);
      if (res is List) {
        final list = res.map((e) {
          if (e is Map) return (e['name'] ?? '').toString();
          return e.toString();
        }).where((e) => e.isNotEmpty).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[ApiCatalog] Could not load categories from API: $e');
    }
    return defaultCategories;
  }

  /// POST /api/catalog/categories
  Future<void> addCategories(List<String> categories) async {
    await _client.post(MmbApiConfig.categories, body: categories);
  }

  /// GET /api/catalog/banners
  Future<List<BannerItem>> getBanners() async {
    try {
      final res = await _client.get(MmbApiConfig.banners);
      if (res is List && res.isNotEmpty) {
        return res
            .map((e) => BannerItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[ApiCatalog] Could not load banners from API: $e');
    }
    return defaultBanners;
  }

  /// POST /api/catalog/banners
  Future<BannerItem> addBanner(BannerItem banner) async {
    final res = await _client.post(MmbApiConfig.banners, body: banner.toMap());
    return BannerItem.fromMap(Map<String, dynamic>.from(res as Map));
  }

  // ==================== REAL-TIME SSE STREAMS ====================

  /// Real-time live stream of products from GET /api/catalog/products/stream
  Stream<List<Product>> watchProducts({
    String? category,
    String? status,
    String? sellerId,
  }) {
    late StreamController<List<Product>> controller;
    StreamSubscription? sseSub;

    List<Product> filter(List<Product> all) {
      return all.where((p) {
        if (category != null && category.isNotEmpty && p.category != category) return false;
        if (status != null && status.isNotEmpty && p.status.name != status) return false;
        if (sellerId != null && sellerId.isNotEmpty && p.sellerId != sellerId) return false;
        return true;
      }).toList();
    }

    controller = StreamController<List<Product>>.broadcast(
      onListen: () async {
        // Initial fetch
        try {
          final initial = await getProducts(category: category, status: status, sellerId: sellerId);
          if (!controller.isClosed) controller.add(initial);
        } catch (e) {
          debugPrint('[ApiCatalog] Initial products fetch failed: $e');
        }

        // Subscribe to SSE
        sseSub = _sseClient.connect(MmbApiConfig.streamProducts).listen(
          (data) {
            if (controller.isClosed) return;
            if (data is List) {
              final parsed = data
                  .map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map)))
                  .toList();
              controller.add(filter(parsed));
            }
          },
          onError: (e) {
            debugPrint('[ApiCatalog] SSE products error: $e');
          },
        );
      },
      onCancel: () {
        sseSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Real-time live stream of banners from GET /api/catalog/banners/stream
  Stream<List<BannerItem>> watchBanners() {
    late StreamController<List<BannerItem>> controller;
    StreamSubscription? sseSub;

    controller = StreamController<List<BannerItem>>.broadcast(
      onListen: () async {
        // Initial fetch
        try {
          final initial = await getBanners();
          if (!controller.isClosed) controller.add(initial);
        } catch (_) {
          if (!controller.isClosed) controller.add(defaultBanners);
        }

        // Subscribe to SSE
        sseSub = _sseClient.connect(MmbApiConfig.streamBanners).listen(
          (data) {
            if (controller.isClosed) return;
            if (data is List && data.isNotEmpty) {
              final parsed = data
                  .map((e) => BannerItem.fromMap(Map<String, dynamic>.from(e as Map)))
                  .toList();
              controller.add(parsed);
            }
          },
          onError: (e) => debugPrint('[ApiCatalog] SSE banners error: $e'),
        );
      },
      onCancel: () => sseSub?.cancel(),
    );

    return controller.stream;
  }

  /// Real-time live stream of categories from GET /api/catalog/categories/stream
  Stream<List<String>> watchCategories() {
    late StreamController<List<String>> controller;
    StreamSubscription? sseSub;

    controller = StreamController<List<String>>.broadcast(
      onListen: () async {
        // Initial fetch
        try {
          final initial = await getCategories();
          if (!controller.isClosed) controller.add(initial);
        } catch (_) {
          if (!controller.isClosed) controller.add(defaultCategories);
        }

        // Subscribe to SSE
        sseSub = _sseClient.connect(MmbApiConfig.streamCategories).listen(
          (data) {
            if (controller.isClosed) return;
            if (data is List && data.isNotEmpty) {
              final parsed = data.map((e) {
                if (e is Map) return (e['name'] ?? '').toString();
                return e.toString();
              }).where((e) => e.isNotEmpty).toList();
              controller.add(parsed);
            }
          },
          onError: (e) => debugPrint('[ApiCatalog] SSE categories error: $e'),
        );
      },
      onCancel: () => sseSub?.cancel(),
    );

    return controller.stream;
  }
}
