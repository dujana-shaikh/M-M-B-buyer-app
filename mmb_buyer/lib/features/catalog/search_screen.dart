import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCategory, this.autofocus = false});
  final String? initialCategory;
  final bool autofocus;
  @override
  ConsumerState<SearchScreen> createState() => _State();
}

class _State extends ConsumerState<SearchScreen> {
  late ProductFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = ProductFilter()..category = widget.initialCategory;
  }

  Future<void> _openFilters(List<Product> all) async {
    final result = await showModalBottomSheet<ProductFilter>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FilterSheet(all: all, initial: _filter.copy()),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(approvedProductsProvider);
    final all = products.valueOrNull ?? const <Product>[];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          autofocus: widget.autofocus,
          onChanged: (v) => setState(() => _filter.query = v),
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: widget.initialCategory ?? 'Search products',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(children: [
            ActionChip(
              avatar: Badge(isLabelVisible: _filter.activeCount > 0, label: Text('${_filter.activeCount}'), child: const Icon(Icons.tune, size: 18)),
              label: const Text('Filters'),
              onPressed: all.isEmpty ? null : () => _openFilters(all),
            ),
            const SizedBox(width: 8),
            if (_filter.activeCount > 0)
              TextButton(onPressed: () => setState(() => _filter = ProductFilter()..query = _filter.query), child: const Text('Clear')),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<SortBy>(
                value: _filter.sort,
                borderRadius: BorderRadius.circular(14),
                items: const [
                  DropdownMenuItem(value: SortBy.newest, child: Text('Newest')),
                  DropdownMenuItem(value: SortBy.priceLow, child: Text('Price: Low to High')),
                  DropdownMenuItem(value: SortBy.priceHigh, child: Text('Price: High to Low')),
                ],
                onChanged: (v) => setState(() => _filter.sort = v!),
              ),
            ),
          ]),
        ),
        Expanded(
          child: AsyncBody<List<Product>>(
            value: products,
            onRetry: () => ref.invalidate(approvedProductsProvider),
            data: (list) {
              final shown = _filter.apply(list);
              if (shown.isEmpty) {
                return const EmptyState(icon: Icons.search_off, title: 'No products found', message: 'Try a different search or clear some filters.');
              }
              return ProductGrid(products: shown);
            },
          ),
        ),
      ]),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.all, required this.initial});
  final List<Product> all;
  final ProductFilter initial;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ProductFilter f = widget.initial;

  List<String> _opts(String? Function(Product) pick) =>
      widget.all.map(pick).whereType<String>().where((e) => e.isNotEmpty).toSet().toList()..sort();

  Widget _dd(String label, String? value, List<String> items, ValueChanged<String?> onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String?>(
          initialValue: items.contains(value) ? value : null,
          decoration: InputDecoration(labelText: label),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Any')),
            ...items.map((e) => DropdownMenuItem<String?>(value: e, child: Text(e))),
          ],
          onChanged: onChanged,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final maxPrice = widget.all.fold<double>(0, (m, p) => p.bulkPrice > m ? p.bulkPrice : m);
    final top = (maxPrice <= 0 ? 1000 : (maxPrice / 1000).ceil() * 1000).toDouble();
    final range = f.price ?? RangeValues(0, top);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            TextButton(onPressed: () => setState(() => f = ProductFilter()..query = f.query..sort = f.sort), child: const Text('Reset')),
          ]),
          const SizedBox(height: 8),
          _dd('Category', f.category, defaultCategories, (v) => setState(() => f.category = v)),
          _dd('Brand', f.brand, _opts((p) => p.brand), (v) => setState(() => f.brand = v)),
          Row(children: [
            Expanded(child: _dd('Storage', f.storage, _opts((p) => p.storage), (v) => setState(() => f.storage = v))),
            const SizedBox(width: 10),
            Expanded(child: _dd('RAM', f.ram, _opts((p) => p.ram), (v) => setState(() => f.ram = v))),
          ]),
          _dd('City', f.city, _opts((p) => p.city), (v) => setState(() => f.city = v)),
          const Text('Condition', style: TextStyle(fontWeight: FontWeight.w600)),
          Wrap(spacing: 8, children: [
            for (final c in ProductCondition.values)
              ChoiceChip(
                label: Text(c.label),
                selected: f.condition == c,
                onSelected: (s) => setState(() => f.condition = s ? c : null),
              ),
          ]),
          const SizedBox(height: 12),
          Text('Price per unit: ${formatINR(range.start)} – ${formatINR(range.end)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          RangeSlider(
            values: range,
            min: 0,
            max: top,
            divisions: 50,
            onChanged: (v) => setState(() => f.price = (v.start == 0 && v.end == top) ? null : v),
          ),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('In stock only'), value: f.inStockOnly, onChanged: (v) => setState(() => f.inStockOnly = v)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => Navigator.pop(context, f), child: const Text('Apply filters')),
        ]),
      ),
    );
  }
}
