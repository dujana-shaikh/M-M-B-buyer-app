import 'package:flutter/material.dart';
import 'package:mmb_core/mmb_core.dart';

enum SortBy { newest, priceLow, priceHigh }

/// Buyer-side filters. Applied in memory on the approved-products list.
class ProductFilter {
  String query = '';
  String? category, brand, storage, ram, city;
  ProductCondition? condition;
  RangeValues? price;
  bool inStockOnly = false;
  SortBy sort = SortBy.newest;

  ProductFilter copy() => ProductFilter()
    ..query = query
    ..category = category
    ..brand = brand
    ..storage = storage
    ..ram = ram
    ..city = city
    ..condition = condition
    ..price = price
    ..inStockOnly = inStockOnly
    ..sort = sort;

  int get activeCount => [category, brand, storage, ram, city, condition, price].where((e) => e != null).length + (inStockOnly ? 1 : 0);

  List<Product> apply(List<Product> all) {
    final q = query.trim().toLowerCase();
    final list = all.where((p) {
      if (q.isNotEmpty && !'${p.name} ${p.brand} ${p.model} ${p.category} ${p.color}'.toLowerCase().contains(q)) return false;
      if (category != null && p.category != category) return false;
      if (brand != null && p.brand != brand) return false;
      if (storage != null && p.storage != storage) return false;
      if (ram != null && p.ram != ram) return false;
      if (city != null && p.city != city) return false;
      if (condition != null && p.condition != condition) return false;
      if (price != null && (p.bulkPrice < price!.start || p.bulkPrice > price!.end)) return false;
      if (inStockOnly && !p.isBuyable) return false;
      return true;
    }).toList();
    final now = DateTime.now();
    switch (sort) {
      case SortBy.newest:
        list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
      case SortBy.priceLow:
        list.sort((a, b) => a.bulkPrice.compareTo(b.bulkPrice));
      case SortBy.priceHigh:
        list.sort((a, b) => b.bulkPrice.compareTo(a.bulkPrice));
    }
    return list;
  }
}

IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('mobile') || n.contains('phone')) return Icons.smartphone;
  if (n.contains('laptop')) return Icons.laptop_mac;
  if (n.contains('watch')) return Icons.watch;
  if (n.contains('tablet')) return Icons.tablet_mac;
  if (n.contains('audio') || n.contains('ear') || n.contains('head')) return Icons.headphones;
  if (n.contains('charger') || n.contains('cable')) return Icons.cable;
  if (n.contains('power')) return Icons.battery_charging_full;
  return Icons.devices_other;
}

const categoryColors = <Color>[
  Color(0xFF1746D1), Color(0xFFFF7A00), Color(0xFF1FA463), Color(0xFF7B2FF7),
  Color(0xFFE5393F), Color(0xFF00A6C7), Color(0xFFF2A900), Color(0xFFE91E8C),
];
