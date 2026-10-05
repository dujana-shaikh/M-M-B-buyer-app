import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool active;
  final int order;
  final List<Color> colors;

  const BannerItem({
    this.id = '',
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.active = true,
    this.order = 0,
    this.colors = const [MmbColors.darkBlue, MmbColors.deepBlue],
  });

  factory BannerItem.fromMap(Map<String, dynamic> m) {
    return BannerItem(
      id: (m['id'] ?? m['_id'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      subtitle: (m['subtitle'] ?? '') as String,
      imageUrl: m['imageUrl'] as String?,
      active: (m['active'] ?? true) as bool,
      order: (m['order'] ?? 0) as int,
      colors: const [MmbColors.darkBlue, MmbColors.deepBlue],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        if (subtitle.isNotEmpty) 'subtitle': subtitle,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'active': active,
        'order': order,
      };
}

const defaultBanners = <BannerItem>[
  BannerItem(
    title: 'Bulk deals on Mobiles',
    subtitle: 'Best wholesale prices from verified distributors',
    colors: [MmbColors.darkBlue, MmbColors.deepBlue],
  ),
  BannerItem(
    title: 'Laptops & Tablets',
    subtitle: 'New, refurbished and open box stock',
    colors: [Color(0xFFFF7A00), Color(0xFFFFA63D)],
  ),
  BannerItem(
    title: 'Accessories in bulk',
    subtitle: 'Chargers, cables, earbuds and more',
    colors: [Color(0xFF7B2FF7), Color(0xFFB66DFF)],
  ),
];
