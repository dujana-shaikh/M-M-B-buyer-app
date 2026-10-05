import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class MmbApiConfig {
  MmbApiConfig._();

  /// Default API base URL.
  /// On Android emulator, localhost is mapped to 10.0.2.2.
  /// On Web / iOS / Desktop, it is http://localhost:5000.
  static String? _customBaseUrl;

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static set baseUrl(String url) {
    _customBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // Auth endpoints
  static String get register => '$baseUrl/api/auth/register';
  static String get login => '$baseUrl/api/auth/login';
  static String get me => '$baseUrl/api/auth/me';

  // Products
  static String get products => '$baseUrl/api/products';
  static String product(String id) => '$baseUrl/api/products/$id';

  // Categories & Banners
  static String get categories => '$baseUrl/api/catalog/categories';
  static String get banners => '$baseUrl/api/catalog/banners';

  // Cart
  static String get cart => '$baseUrl/api/cart';
  static String get cartQty => '$baseUrl/api/cart/qty';
  static String cartItem(String productId) => '$baseUrl/api/cart/$productId';

  // Favorites
  static String get favorites => '$baseUrl/api/favorites';
  static String get favoritesToggle => '$baseUrl/api/favorites/toggle';

  // Enquiries
  static String get enquiries => '$baseUrl/api/enquiries';

  // Orders
  static String get orders => '$baseUrl/api/orders';

  // SSE Streams
  static String get streamProducts => '$baseUrl/api/catalog/products/stream';
  static String get streamBanners => '$baseUrl/api/catalog/banners/stream';
  static String get streamCategories => '$baseUrl/api/catalog/categories/stream';
  static String streamCart(String userId) => '$baseUrl/api/cart/stream?userId=$userId';
  static String streamFavorites(String userId) => '$baseUrl/api/favorites/stream?userId=$userId';
  static String streamEnquiries(String buyerId) => '$baseUrl/api/enquiries/stream?buyerId=$buyerId';
}
