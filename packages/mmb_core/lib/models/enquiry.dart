import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';
import 'cart_item.dart';

/// One enquiry per seller. A mixed cart is split into one Enquiry per seller
/// at checkout, so each seller only ever sees their own items.
class Enquiry extends Equatable {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final List<CartItem> items;
  final double totalAmount;
  final String? note;
  final EnquiryStatus status;
  final DateTime? createdAt;

  const Enquiry({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerId,
    required this.items,
    required this.totalAmount,
    this.note,
    this.status = EnquiryStatus.newEnquiry,
    this.createdAt,
  });

  factory Enquiry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return Enquiry.fromMap({...m, 'id': doc.id});
  }

  factory Enquiry.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    List<CartItem> parsedItems = [];
    if (m['items'] is List && (m['items'] as List).isNotEmpty) {
      parsedItems = (m['items'] as List)
          .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (m['productId'] != null) {
      parsedItems = [
        CartItem(
          productId: m['productId'].toString(),
          sellerId: (m['sellerId'] ?? '').toString(),
          name: (m['productName'] ?? 'Product').toString(),
          imageUrl: '',
          variantLabel: '',
          unitPrice: 0,
          minOrderQty: 1,
          quantity: ((m['quantityRequired'] ?? 1) as num).toInt(),
        )
      ];
    }

    return Enquiry(
      id: (m['id'] ?? m['_id'] ?? '') as String,
      buyerId: (m['buyerId'] ?? m['userId'] ?? '') as String,
      buyerName: (m['buyerName'] ?? '') as String,
      buyerPhone: (m['buyerPhone'] ?? m['phone'] ?? '') as String,
      sellerId: (m['sellerId'] ?? '') as String,
      items: parsedItems,
      totalAmount: ((m['totalAmount'] ?? 0) as num).toDouble(),
      note: (m['note'] ?? m['message']) as String?,
      status: EnquiryStatusX.parse(m['status'] as String?),
      createdAt: parseDate(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'sellerId': sellerId,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'note': note,
        'status': status.value,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  Map<String, dynamic> toApiJson() => {
        'id': id,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'sellerId': sellerId,
        'productId': items.isNotEmpty ? items.first.productId : '',
        'productName': items.isNotEmpty ? items.first.name : '',
        'quantityRequired': items.isNotEmpty ? items.first.quantity : 1,
        'message': note ?? (items.isNotEmpty ? 'Enquiry for ${items.first.name}' : 'Enquiry'),
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'note': note,
      };

  @override
  List<Object?> get props => [id, status, totalAmount];
}
