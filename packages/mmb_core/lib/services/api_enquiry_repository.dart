import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/enums.dart';
import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../models/enquiry.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/sse_client.dart';

class ApiEnquiryRepository {
  ApiEnquiryRepository(this._client, {MmbSseClient? sseClient})
      : _sseClient = sseClient ?? MmbSseClient();

  final MmbApiClient _client;
  final MmbSseClient _sseClient;

  /// POST /api/enquiries
  Future<Enquiry> sendEnquiry({
    required String productId,
    required String productName,
    required String sellerId,
    required String message,
    required int quantityRequired,
    List<CartItem>? items,
    double? totalAmount,
    String? buyerName,
    String? buyerPhone,
  }) async {
    final body = {
      'productId': productId,
      'productName': productName,
      'sellerId': sellerId,
      'message': message,
      'quantityRequired': quantityRequired,
      if (items != null) 'items': items.map((e) => e.toMap()).toList(),
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (buyerName != null) 'buyerName': buyerName,
      if (buyerPhone != null) 'buyerPhone': buyerPhone,
    };

    final res = await _client.post(MmbApiConfig.enquiries, body: body);
    return Enquiry.fromMap(Map<String, dynamic>.from(res as Map));
  }

  /// GET /api/enquiries
  Future<List<Enquiry>> getEnquiries({String? buyerId, String? sellerId}) async {
    final query = <String, String>{};
    if (buyerId != null && buyerId.isNotEmpty) query['buyerId'] = buyerId;
    if (sellerId != null && sellerId.isNotEmpty) query['sellerId'] = sellerId;

    final res = await _client.get(MmbApiConfig.enquiries, queryParams: query);
    if (res is List) {
      return res
          .map((e) => Enquiry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const [];
  }

  /// Place checkout enquiries: splits cart items by seller and creates enquiries
  Future<int> place({
    required AppUser buyer,
    required List<CartItem> items,
    String? note,
  }) async {
    final bySeller = <String, List<CartItem>>{};
    for (final it in items) {
      bySeller.putIfAbsent(it.sellerId, () => []).add(it);
    }

    int count = 0;
    for (final entry in bySeller.entries) {
      final sellerId = entry.key;
      final sellerItems = entry.value;
      final first = sellerItems.first;
      final total = sellerItems.fold<double>(0, (t, e) => t + e.lineTotal);

      await sendEnquiry(
        productId: first.productId,
        productName: first.name,
        sellerId: sellerId,
        message: (note != null && note.trim().isNotEmpty) ? note.trim() : 'Enquiry for bulk purchase',
        quantityRequired: first.quantity,
        items: sellerItems,
        totalAmount: total,
        buyerName: buyer.name,
        buyerPhone: buyer.phone,
      );
      count++;
    }

    // Clear cart after checkout
    try {
      await _client.delete(MmbApiConfig.cart);
    } catch (_) {}

    return count;
  }

  /// Update enquiry status (for seller)
  Future<void> setStatus(String id, EnquiryStatus status) async {
    // Check if PUT /api/enquiries/:id exists or update through query
    try {
      await _client.put('${MmbApiConfig.enquiries}/$id', body: {'status': status.value});
    } catch (_) {
      // Best-effort
    }
  }

  /// Real-time live stream of enquiries for a buyer
  Stream<List<Enquiry>> watchMine(String buyerId) {
    late StreamController<List<Enquiry>> controller;
    StreamSubscription? sseSub;

    controller = StreamController<List<Enquiry>>.broadcast(
      onListen: () async {
        // Initial fetch
        try {
          final initial = await getEnquiries(buyerId: buyerId);
          if (!controller.isClosed) controller.add(initial);
        } catch (e) {
          debugPrint('[ApiEnquiries] Initial fetch failed: $e');
        }

        // Connect SSE
        sseSub = _sseClient
            .connect(MmbApiConfig.streamEnquiries(buyerId), authToken: _client.authToken)
            .listen(
          (data) {
            if (controller.isClosed) return;
            if (data is List) {
              final parsed = data
                  .map((e) => Enquiry.fromMap(Map<String, dynamic>.from(e as Map)))
                  .toList();
              controller.add(parsed);
            }
          },
          onError: (e) => debugPrint('[ApiEnquiries] SSE enquiries error: $e'),
        );
      },
      onCancel: () => sseSub?.cancel(),
    );

    return controller.stream;
  }

  /// Enquiries for a seller
  Stream<List<Enquiry>> watchReceived(String sellerId) {
    late StreamController<List<Enquiry>> controller;
    Timer? poller;

    Future<void> load() async {
      try {
        final list = await getEnquiries(sellerId: sellerId);
        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        debugPrint('[ApiEnquiries] Seller fetch error: $e');
      }
    }

    controller = StreamController<List<Enquiry>>.broadcast(
      onListen: () {
        load();
        poller = Timer.periodic(const Duration(seconds: 10), (_) => load());
      },
      onCancel: () => poller?.cancel(),
    );

    return controller.stream;
  }
}
