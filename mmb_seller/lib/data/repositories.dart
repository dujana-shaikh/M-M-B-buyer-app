import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mmb_core/mmb_core.dart';

/// Scoped product repository for distributor/seller app backed by REST and SSE APIs.
class ProductRepository {
  ProductRepository(this._api, [this._storage]);
  final ApiCatalogRepository _api;
  final FirebaseStorage? _storage;

  /// Watch logged-in distributor's products via SSE stream
  /// GET /api/catalog/products/stream
  Stream<List<Product>> watchMine(String uid) =>
      _api.watchProducts(sellerId: uid);

  String newId() => 'prod-${DateTime.now().millisecondsSinceEpoch % 1000000}';

  /// Uploads images to Firebase Storage or encodes as data URIs
  Future<List<String>> uploadImages(String uid, String productId, List<Uint8List> images) async {
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      if (_storage != null) {
        try {
          final stamp = DateTime.now().millisecondsSinceEpoch;
          final ref = _storage.ref('products/$uid/$productId/${stamp}_$i.jpg');
          await ref.putData(images[i], SettableMetadata(contentType: 'image/jpeg'));
          urls.add(await ref.getDownloadURL());
          continue;
        } catch (_) {
          // Fallback to data URI below
        }
      }
      final b64 = base64Encode(images[i]);
      urls.add('data:image/jpeg;base64,$b64');
    }
    return urls;
  }

  /// POST /api/products
  Future<void> create(Product p) => _api.createProduct(p);

  /// PUT /api/products/:id
  Future<void> update(Product p) => _api.updateProduct(p.id, p.toJson());

  /// PUT /api/products/:id
  Future<void> setStock(String id, StockStatus s) =>
      _api.updateProduct(id, {'stockStatus': s.name});

  /// DELETE /api/products/:id
  Future<void> delete(Product p) => _api.deleteProduct(p.id);
}

class EnquiryRepository {
  EnquiryRepository(this._api);
  final ApiEnquiryRepository _api;

  /// GET /api/enquiries?sellerId=<sellerId>
  Stream<List<Enquiry>> watchReceived(String sellerId) =>
      _api.watchReceived(sellerId);

  /// PUT /api/enquiries/:id
  Future<void> setStatus(String id, EnquiryStatus status) =>
      _api.setStatus(id, status);
}

class SellerOrderRepository {
  SellerOrderRepository(this._api);
  final ApiOrderRepository _api;

  /// GET /api/orders
  Future<List<OrderModel>> getOrders() => _api.getOrders();
}
