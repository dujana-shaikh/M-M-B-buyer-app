import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../constants/enums.dart';

class AppUser extends Equatable {
  final String uid;
  final String name;
  final String? email;
  final String phone;
  final String? whatsapp;
  final String? shopName;
  final String? city;
  final String? area;
  final UserRole role;
  final ApprovalStatus status;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    this.email,
    this.whatsapp,
    this.shopName,
    this.city,
    this.area,
    this.createdAt,
  });

  bool get isApprovedSeller =>
      role == UserRole.seller && status == ApprovalStatus.approved;

  String get id => uid;

  factory AppUser.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final rawStatus = m['status']?.toString();
    final status = (rawStatus == 'active' || rawStatus == 'approved')
        ? ApprovalStatus.approved
        : enumFromName(ApprovalStatus.values, rawStatus, ApprovalStatus.pending);

    return AppUser(
      uid: (m['uid'] ?? m['id'] ?? m['_id'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      email: m['email'] as String?,
      phone: (m['phone'] ?? '') as String,
      whatsapp: m['whatsapp'] as String?,
      shopName: m['shopName'] as String?,
      city: m['city'] as String?,
      area: m['area'] as String?,
      role: enumFromName(UserRole.values, m['role'] as String?, UserRole.buyer),
      status: status,
      createdAt: parseDate(m['createdAt']),
    );
  }

  /// Note: role/status are written only at registration; rules block later edits.
  Map<String, dynamic> toMap() => {
        'id': uid,
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'whatsapp': whatsapp,
        'shopName': shopName,
        'city': city,
        'area': area,
        'role': role.name,
        'status': status.name,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [uid, name, email, phone, whatsapp, shopName, city, area, role, status];
}
