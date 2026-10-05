import 'package:flutter/foundation.dart';
import '../models/order.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';

class ApiOrderRepository {
  ApiOrderRepository(this._client);
  final MmbApiClient _client;

  /// POST /api/orders
  Future<OrderModel> placeOrder({
    String? id,
    required String customerName,
    required String phone,
    required String address,
    required List<OrderItem> items,
    required double totalAmount,
    String orderStatus = 'Processing',
    String paymentMethod = 'COD',
  }) async {
    final orderId = id ?? 'ORD-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final body = {
      'id': orderId,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderStatus': orderStatus,
      'paymentMethod': paymentMethod,
    };

    final res = await _client.post(MmbApiConfig.orders, body: body);
    return OrderModel.fromMap(Map<String, dynamic>.from(res as Map));
  }

  /// GET /api/orders
  Future<List<OrderModel>> getOrders() async {
    try {
      final res = await _client.get(MmbApiConfig.orders);
      if (res is List) {
        return res
            .map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else if (res is Map && res['value'] is List) {
        return (res['value'] as List)
            .map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[ApiOrder] Failed to get orders: $e');
    }
    return const [];
  }
}
