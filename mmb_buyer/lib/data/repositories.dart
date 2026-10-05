import 'package:mmb_core/mmb_core.dart';

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiCatalogRepository _api;

  /// Only admin-approved products streamed in real-time via SSE
  /// GET /api/catalog/products/stream
  Stream<List<Product>> watchApproved() => _api.watchProducts(status: 'approved');

  /// Real-time banners streamed via GET /api/catalog/banners/stream
  Stream<List<BannerItem>> watchBanners() => _api.watchBanners();

  /// Real-time categories streamed via GET /api/catalog/categories/stream
  Stream<List<String>> watchCategories() => _api.watchCategories();

  Future<List<Product>> getApproved() => _api.getProducts(status: 'approved');
  Future<Product> getProduct(String id) => _api.getProduct(id);
}

class CartRepository {
  CartRepository(this._api);
  final ApiCartRepository _api;

  /// Real-time live cart streamed via GET /api/cart/stream?userId=<uid>
  Stream<List<CartItem>> watch(String uid) => _api.watch(uid);

  /// POST /api/cart
  Future<void> upsert(String uid, CartItem item) =>
      _api.addToCart(item.productId, item.quantity, userId: uid);

  /// PUT /api/cart/qty
  Future<void> setQty(String uid, String productId, int qty) =>
      _api.updateQty(productId, qty);

  /// DELETE /api/cart/:productId
  Future<void> remove(String uid, String productId) =>
      _api.remove(uid, productId);

  /// DELETE /api/cart
  Future<void> clear() => _api.clearCart();
}

class FavoritesRepository {
  FavoritesRepository(this._api);
  final ApiFavoritesRepository _api;

  /// Real-time live favorites streamed via GET /api/favorites/stream?userId=<uid>
  Stream<Set<String>> watchIds(String uid) => _api.watchIds(uid);

  /// POST /api/favorites/toggle
  Future<void> toggle(String uid, String productId, bool currentlyFav) =>
      _api.toggleFavorite(productId);
}

class EnquiryRepository {
  EnquiryRepository(this._api);
  final ApiEnquiryRepository _api;

  /// Real-time live enquiries streamed via GET /api/enquiries/stream?buyerId=<uid>
  Stream<List<Enquiry>> watchMine(String uid) => _api.watchMine(uid);

  /// POST /api/enquiries
  Future<int> place({required AppUser buyer, required List<CartItem> items, String? note}) =>
      _api.place(buyer: buyer, items: items, note: note);

  Future<Enquiry> sendDirectEnquiry({
    required String productId,
    required String productName,
    required String sellerId,
    required String message,
    required int quantityRequired,
    String? buyerName,
    String? buyerPhone,
  }) =>
      _api.sendEnquiry(
        productId: productId,
        productName: productName,
        sellerId: sellerId,
        message: message,
        quantityRequired: quantityRequired,
        buyerName: buyerName,
        buyerPhone: buyerPhone,
      );
}

class OrderRepository {
  OrderRepository(this._api);
  final ApiOrderRepository _api;

  /// POST /api/orders
  Future<OrderModel> placeOrder({
    required String customerName,
    required String phone,
    required String address,
    required List<OrderItem> items,
    required double totalAmount,
    String orderStatus = 'Processing',
    String paymentMethod = 'COD',
  }) =>
      _api.placeOrder(
        customerName: customerName,
        phone: phone,
        address: address,
        items: items,
        totalAmount: totalAmount,
        orderStatus: orderStatus,
        paymentMethod: paymentMethod,
      );

  /// GET /api/orders
  Future<List<OrderModel>> getOrders() => _api.getOrders();
}
