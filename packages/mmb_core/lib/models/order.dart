import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get lineTotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: (m['productId'] ?? m['id'] ?? '') as String,
        name: (m['name'] ?? m['productName'] ?? '') as String,
        quantity: (m['quantity'] ?? 1) as int,
        price: ((m['price'] ?? m['bulkPrice'] ?? 0) as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'price': price,
      };

  @override
  List<Object?> get props => [productId, name, quantity, price];
}

class OrderModel extends Equatable {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final List<OrderItem> items;
  final double totalAmount;
  final String orderStatus;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    required this.totalAmount,
    this.orderStatus = 'Processing',
    this.paymentMethod = 'COD',
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final rawItems = m['items'] as List? ?? const [];
    final parsedItems = rawItems.map((e) {
      if (e is Map<String, dynamic>) return OrderItem.fromMap(e);
      if (e is Map) return OrderItem.fromMap(Map<String, dynamic>.from(e));
      return const OrderItem(productId: '', name: 'Item', quantity: 1, price: 0);
    }).toList();

    return OrderModel(
      id: (m['id'] ?? m['_id'] ?? '') as String,
      customerName: (m['customerName'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      address: (m['address'] ?? '') as String,
      items: parsedItems,
      totalAmount: ((m['totalAmount'] ?? 0) as num).toDouble(),
      orderStatus: (m['orderStatus'] ?? 'Processing') as String,
      paymentMethod: (m['paymentMethod'] ?? 'COD') as String,
      createdAt: parseDate(m['createdAt']),
      updatedAt: parseDate(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'orderStatus': orderStatus,
        'paymentMethod': paymentMethod,
      };

  @override
  List<Object?> get props => [id, customerName, totalAmount, orderStatus, createdAt];
}
