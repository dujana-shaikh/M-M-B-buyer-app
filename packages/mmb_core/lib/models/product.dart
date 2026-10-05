import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

class Product extends Equatable {
  final String id;
  final String sellerId; // owner: linked to Firebase Auth uid
  final String name;
  final String brand;
  final String model;
  final String category;
  final String? storage; // e.g. 128GB
  final String? ram; // e.g. 8GB
  final String color;
  final ProductCondition condition;
  final int quantityAvailable;
  final double bulkPrice; // price per unit
  final int minOrderQty;
  final String description;
  final List<String> imageUrls;

  // Seller details (denormalised so buyers need no extra read)
  final String sellerName;
  final String shopName;
  final String city;
  final String? area;
  final String contactNumber;
  final String whatsappNumber;

  // Admin / stock control
  final ApprovalStatus status; // set by admin only
  final StockStatus stockStatus; // set by seller
  final bool featured; // admin: trending / featured
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.color,
    required this.condition,
    required this.quantityAvailable,
    required this.bulkPrice,
    required this.minOrderQty,
    required this.description,
    required this.imageUrls,
    required this.sellerName,
    required this.shopName,
    required this.city,
    required this.contactNumber,
    required this.whatsappNumber,
    this.storage,
    this.ram,
    this.area,
    this.status = ApprovalStatus.pending,
    this.stockStatus = StockStatus.inStock,
    this.featured = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isBuyable =>
      status == ApprovalStatus.approved &&
      stockStatus == StockStatus.inStock &&
      quantityAvailable > 0;

  String get variantLabel =>
      [storage, ram].where((e) => e != null && e.isNotEmpty).join(' • ');

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return Product.fromMap({...m, 'id': doc.id});
  }

  factory Product.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final specs = m['specs'] is Map ? Map<String, dynamic>.from(m['specs']) : const <String, dynamic>{};
    final conditionRaw = (m['condition'] ?? specs['condition'])?.toString();
    ProductCondition cond = ProductCondition.newItem;
    if (conditionRaw != null) {
      final cLow = conditionRaw.toLowerCase();
      if (cLow.contains('refurbish')) cond = ProductCondition.refurbished;
      else if (cLow.contains('open')) cond = ProductCondition.openBox;
      else cond = enumFromName(ProductCondition.values, conditionRaw, ProductCondition.newItem);
    }

    List<String> images = const [];
    if (m['imageUrls'] is List) {
      images = List<String>.from(m['imageUrls']);
    } else if (m['image'] != null && (m['image'] as String).isNotEmpty) {
      images = [m['image'] as String];
    }

    final rawStatus = m['status']?.toString();
    final status = (rawStatus == 'approved' || rawStatus == 'active')
        ? ApprovalStatus.approved
        : enumFromName(ApprovalStatus.values, rawStatus, ApprovalStatus.pending);

    return Product(
      id: (m['id'] ?? m['_id'] ?? '') as String,
      sellerId: (m['sellerId'] ?? '') as String,
      name: (m['name'] ?? m['title'] ?? '') as String,
      brand: (m['brand'] ?? '') as String,
      model: (m['model'] ?? '') as String,
      category: (m['category'] ?? '') as String,
      storage: (m['storage'] ?? specs['storage']) as String?,
      ram: (m['ram'] ?? specs['ram']) as String?,
      color: (m['color'] ?? '') as String,
      condition: cond,
      quantityAvailable: ((m['quantityAvailable'] ?? m['quantity'] ?? 10) as num).toInt(),
      bulkPrice: ((m['bulkPrice'] ?? m['price'] ?? 0) as num).toDouble(),
      minOrderQty: ((m['minOrderQty'] ?? 1) as num).toInt(),
      description: (m['description'] ?? '') as String,
      imageUrls: images,
      sellerName: (m['sellerName'] ?? 'Verified Seller') as String,
      shopName: (m['shopName'] ?? 'Distributor Store') as String,
      city: (m['city'] ?? 'Mumbai') as String,
      area: m['area'] as String?,
      contactNumber: (m['contactNumber'] ?? m['phone'] ?? '') as String,
      whatsappNumber: (m['whatsappNumber'] ?? m['whatsapp'] ?? m['contactNumber'] ?? '') as String,
      status: status,
      stockStatus: enumFromName(
          StockStatus.values, m['stockStatus'] as String?, StockStatus.inStock),
      featured: (m['featured'] ?? false) as bool,
      createdAt: parseDate(m['createdAt']),
      updatedAt: parseDate(m['updatedAt']),
    );
  }

  /// Fields a seller may write. `status` is only included on create (pending).
  Map<String, dynamic> toMap({bool isCreate = false}) => {
        'id': id,
        'sellerId': sellerId,
        'name': name,
        'title': name,
        'brand': brand,
        'model': model,
        'category': category,
        'storage': storage,
        'ram': ram,
        'color': color,
        'condition': condition.name,
        'quantityAvailable': quantityAvailable,
        'price': bulkPrice,
        'bulkPrice': bulkPrice,
        'minOrderQty': minOrderQty,
        'description': description,
        'image': imageUrls.isNotEmpty ? imageUrls.first : '',
        'imageUrls': imageUrls,
        'sellerName': sellerName,
        'shopName': shopName,
        'city': city,
        'area': area,
        'contactNumber': contactNumber,
        'whatsappNumber': whatsappNumber,
        'stockStatus': stockStatus.name,
        'specs': {
          if (ram != null) 'ram': ram,
          if (storage != null) 'storage': storage,
          'condition': condition.label,
        },
        if (isCreate) 'status': ApprovalStatus.pending.name,
        if (isCreate) 'featured': false,
        if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toJson({bool isCreate = false}) => {
        'id': id,
        'name': name,
        'title': name,
        'category': category,
        'price': bulkPrice,
        'bulkPrice': bulkPrice,
        'originalPrice': bulkPrice,
        'brand': brand,
        'model': model,
        'color': color,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'shopName': shopName,
        'city': city,
        'area': area,
        'contactNumber': contactNumber,
        'whatsappNumber': whatsappNumber,
        'status': status.name,
        'stockStatus': stockStatus.name,
        'quantityAvailable': quantityAvailable,
        'minOrderQty': minOrderQty,
        'description': description,
        'image': imageUrls.isNotEmpty ? imageUrls.first : '',
        'imageUrls': imageUrls,
        'specs': {
          'ram': ram ?? '',
          'storage': storage ?? '',
          'condition': condition.label,
        },
      };

  @override
  List<Object?> get props => [id, sellerId, name, bulkPrice, status, stockStatus];
}
