import 'package:equatable/equatable.dart';

/// Snapshot of a product in the buyer's cart (users/{uid}/cart/{productId}).
class CartItem extends Equatable {
  final String productId;
  final String sellerId;
  final String name;
  final String imageUrl;
  final String variantLabel;
  final double unitPrice;
  final int minOrderQty;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.sellerId,
    required this.name,
    required this.imageUrl,
    required this.variantLabel,
    required this.unitPrice,
    required this.minOrderQty,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        sellerId: sellerId,
        name: name,
        imageUrl: imageUrl,
        variantLabel: variantLabel,
        unitPrice: unitPrice,
        minOrderQty: minOrderQty,
        quantity: quantity ?? this.quantity,
      );

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
        productId: (m['productId'] ?? m['id'] ?? '') as String,
        sellerId: (m['sellerId'] ?? '') as String,
        name: (m['name'] ?? m['productName'] ?? m['title'] ?? 'Product') as String,
        imageUrl: (m['imageUrl'] ?? m['image'] ?? '') as String,
        variantLabel: (m['variantLabel'] ?? '') as String,
        unitPrice: ((m['unitPrice'] ?? m['price'] ?? m['bulkPrice'] ?? 0) as num).toDouble(),
        minOrderQty: ((m['minOrderQty'] ?? 1) as num).toInt(),
        quantity: ((m['quantity'] ?? 1) as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'sellerId': sellerId,
        'name': name,
        'imageUrl': imageUrl,
        'variantLabel': variantLabel,
        'unitPrice': unitPrice,
        'minOrderQty': minOrderQty,
        'quantity': quantity,
      };

  @override
  List<Object?> get props => [productId, quantity, unitPrice];
}
