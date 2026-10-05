enum UserRole { buyer, seller, admin }

/// Used for both distributor accounts and product posts (admin-controlled).
enum ApprovalStatus { pending, approved, rejected, hidden, removed, suspended }

enum StockStatus { inStock, outOfStock }

enum ProductCondition { newItem, refurbished, openBox }

enum EnquiryStatus { newEnquiry, contacted, confirmed, completed, cancelled }

T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

extension ProductConditionLabel on ProductCondition {
  String get label => switch (this) {
        ProductCondition.newItem => 'New',
        ProductCondition.refurbished => 'Refurbished',
        ProductCondition.openBox => 'Open Box',
      };
}

extension StockStatusLabel on StockStatus {
  String get label => this == StockStatus.inStock ? 'In Stock' : 'Out of Stock';
}

extension EnquiryStatusX on EnquiryStatus {
  /// Value stored in Firestore ("new" is required by the security rules on create).
  String get value => this == EnquiryStatus.newEnquiry ? 'new' : name;

  String get label => switch (this) {
        EnquiryStatus.newEnquiry => 'New',
        EnquiryStatus.contacted => 'Contacted',
        EnquiryStatus.confirmed => 'Confirmed',
        EnquiryStatus.completed => 'Completed',
        EnquiryStatus.cancelled => 'Cancelled',
      };

  static EnquiryStatus parse(String? v) => EnquiryStatus.values.firstWhere(
        (e) => e.value == v,
        orElse: () => EnquiryStatus.newEnquiry,
      );
}
