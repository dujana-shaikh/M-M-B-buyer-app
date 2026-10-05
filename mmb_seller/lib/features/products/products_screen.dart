import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/providers.dart';
import 'product_form_screen.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override
  ConsumerState<ProductsScreen> createState() => _State();
}

class _State extends ConsumerState<ProductsScreen> {
  String _q = '';
  String? _category;
  String? _brand;
  StockStatus? _stock;

  bool _match(Product p) {
    final q = _q.trim().toLowerCase();
    if (q.isNotEmpty && !('${p.name} ${p.brand} ${p.model}'.toLowerCase().contains(q))) return false;
    if (_category != null && p.category != _category) return false;
    if (_brand != null && p.brand != _brand) return false;
    if (_stock != null && p.stockStatus != _stock) return false;
    return true;
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${p.name}" will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: MmbColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(productRepositoryProvider).delete(p);
      if (mounted) showSnack(context, 'Product deleted');
    } catch (_) {
      if (mounted) showSnack(context, 'Could not delete product', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(myProductsProvider);
    final all = products.valueOrNull ?? const <Product>[];
    final brands = all.map((e) => e.brand).where((b) => b.isNotEmpty).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('My Products')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MmbColors.orange,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Search name, brand or model', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _Filter<String>(hint: 'Category', value: _category, items: defaultCategories, label: (e) => e, onChanged: (v) => setState(() => _category = v)),
              _Filter<String>(hint: 'Brand', value: _brand, items: brands, label: (e) => e, onChanged: (v) => setState(() => _brand = v)),
              _Filter<StockStatus>(hint: 'Stock', value: _stock, items: StockStatus.values, label: (e) => e.label, onChanged: (v) => setState(() => _stock = v)),
            ],
          ),
        ),
        Expanded(
          child: AsyncBody<List<Product>>(
            value: products,
            onRetry: () => ref.invalidate(myProductsProvider),
            data: (list) {
              final shown = list.where(_match).toList();
              if (list.isEmpty) {
                return const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products yet', message: 'Tap + to add your first product.');
              }
              if (shown.isEmpty) {
                return const EmptyState(icon: Icons.search_off, title: 'No matching products', message: 'Try changing your search or filters.');
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: shown.length,
                itemBuilder: (_, i) => _ProductTile(
                  product: shown[i],
                  onEdit: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductFormScreen(product: shown[i]))),
                  onDelete: () => _delete(shown[i]),
                  onToggleStock: (v) => ref.read(productRepositoryProvider).setStock(shown[i].id, v ? StockStatus.inStock : StockStatus.outOfStock),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _Filter<T> extends StatelessWidget {
  const _Filter({required this.hint, required this.value, required this.items, required this.label, required this.onChanged});
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: value == null ? Theme.of(context).cardTheme.color : MmbColors.yellow.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T?>(
              value: value,
              hint: Text(hint),
              borderRadius: BorderRadius.circular(14),
              items: [
                DropdownMenuItem<T?>(value: null, child: Text('All ${hint.toLowerCase()}')),
                ...items.map((e) => DropdownMenuItem<T?>(value: e, child: Text(label(e)))),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      );
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onEdit, required this.onDelete, required this.onToggleStock});
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleStock;

  (String, Color) get _approval => switch (product.status) {
        ApprovalStatus.approved => ('Live', MmbColors.success),
        ApprovalStatus.pending => ('Pending review', MmbColors.orange),
        ApprovalStatus.rejected => ('Rejected', MmbColors.danger),
        ApprovalStatus.hidden => ('Hidden by MMB', Colors.grey),
        _ => (product.status.name, Colors.grey),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _approval;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 84, height: 84, child: MmbImage(product.imageUrls.isEmpty ? null : product.imageUrls.first, radius: 12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${product.brand} • ${product.model}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                if (product.variantLabel.isNotEmpty) Text(product.variantLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${formatINR(product.bulkPrice)} / unit', style: const TextStyle(color: MmbColors.deepBlue, fontWeight: FontWeight.w800)),
                Text('Qty ${product.quantityAvailable} • MOQ ${product.minOrderQty}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: [
                  StatusChip(label, color),
                  const Spacer(),
                  Text(product.stockStatus == StockStatus.inStock ? 'In stock' : 'Out', style: const TextStyle(fontSize: 12)),
                  Switch(value: product.stockStatus == StockStatus.inStock, onChanged: onToggleStock),
                ]),
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
