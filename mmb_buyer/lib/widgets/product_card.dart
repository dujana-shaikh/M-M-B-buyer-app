import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../data/providers.dart';
import '../features/catalog/product_detail_screen.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoriteIdsProvider).valueOrNull?.contains(product.id) ?? false;
    final out = !product.isBuyable;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              MmbImage(product.imageUrls.isEmpty ? null : product.imageUrls.first),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () {
                    final uid = ref.read(authStateProvider).valueOrNull?.uid;
                    if (uid != null) ref.read(favoritesRepositoryProvider).toggle(uid, product.id, fav);
                  },
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 18, color: fav ? MmbColors.danger : Colors.grey),
                  ),
                ),
              ),
              if (product.condition != ProductCondition.newItem)
                Positioned(top: 6, left: 6, child: StatusChip(product.condition.label, MmbColors.orange)),
              if (out) Container(color: Colors.white70, alignment: Alignment.center, child: const Text('OUT OF STOCK', style: TextStyle(fontWeight: FontWeight.w800, color: MmbColors.danger))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (product.variantLabel.isNotEmpty) Text(product.variantLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 4),
              Text(formatINR(product.bulkPrice), style: const TextStyle(color: MmbColors.deepBlue, fontWeight: FontWeight.w900, fontSize: 16)),
              Text('Bulk price • MOQ ${product.minOrderQty}', style: const TextStyle(color: MmbColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, this.shrink = false});
  final List<Product> products;
  final bool shrink;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: shrink,
        physics: shrink ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68),
        itemCount: products.length,
        itemBuilder: (_, i) => ProductCard(product: products[i]),
      );
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.min, required this.max, required this.onChanged});
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove), onPressed: value > min ? () => onChanged(value - 1) : null),
          SizedBox(width: 44, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.add), onPressed: value < max ? () => onChanged(value + 1) : null),
        ]),
      );
}
