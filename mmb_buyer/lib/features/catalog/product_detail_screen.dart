import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/providers.dart';
import '../../widgets/product_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;
  @override
  ConsumerState<ProductDetailScreen> createState() => _State();
}

class _State extends ConsumerState<ProductDetailScreen> {
  late int _qty = widget.product.minOrderQty;
  int _page = 0;

  Product get p => widget.product;
  int get _max => p.quantityAvailable < p.minOrderQty ? p.minOrderQty : p.quantityAvailable;

  String get _message =>
      'Hello, I am interested in ${p.name}${p.variantLabel.isEmpty ? '' : ' (${p.variantLabel})'} on MMB. '
      'I want to buy $_qty units at ${formatINR(p.bulkPrice)} each. Is it available?';

  Future<void> _contact(Future<bool> Function() action) async {
    final ok = await action().catchError((_) => false);
    if (!ok && mounted) showSnack(context, 'Could not open the app on this device', error: true);
  }

  Future<void> _addToCart() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    try {
      await ref.read(cartRepositoryProvider).upsert(
            uid,
            CartItem(
              productId: p.id,
              sellerId: p.sellerId,
              name: p.name,
              imageUrl: p.imageUrls.isEmpty ? '' : p.imageUrls.first,
              variantLabel: p.variantLabel,
              unitPrice: p.bulkPrice,
              minOrderQty: p.minOrderQty,
              quantity: _qty,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Added $_qty × ${p.name} to cart'),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              ref.read(tabIndexProvider.notifier).state = 2;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ));
    } catch (_) {
      if (mounted) showSnack(context, 'Could not add to cart', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = ref.watch(favoriteIdsProvider).valueOrNull?.contains(p.id) ?? false;
    final images = p.imageUrls.isEmpty ? <String?>[null] : p.imageUrls;
    final buyable = p.isBuyable;

    Widget spec(String k, String? v) => (v == null || v.isEmpty)
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              SizedBox(width: 110, child: Text(k, style: TextStyle(color: Colors.grey.shade600))),
              Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          );

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 320,
          actions: [
            IconButton(
              icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? MmbColors.yellow : Colors.white),
              onPressed: () {
                final uid = ref.read(authStateProvider).valueOrNull?.uid;
                if (uid != null) ref.read(favoritesRepositoryProvider).toggle(uid, p.id, fav);
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              PageView.builder(
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => MmbImage(images[i], fit: BoxFit.contain),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < images.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(color: i == _page ? MmbColors.orange : Colors.grey, borderRadius: BorderRadius.circular(3)),
                      ),
                  ]),
                ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${p.brand} • ${p.model}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatINR(p.bulkPrice), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: MmbColors.deepBlue)),
                const Text('  per unit (bulk)', style: TextStyle(color: MmbColors.success, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                StatusChip(p.condition.label, MmbColors.deepBlue),
                StatusChip(buyable ? 'In stock: ${p.quantityAvailable}' : 'Out of stock', buyable ? MmbColors.success : MmbColors.danger),
                StatusChip('Min order: ${p.minOrderQty}', MmbColors.orange),
              ]),
              const SizedBox(height: 18),
              if (buyable)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Select quantity', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(children: [
                        QtyStepper(value: _qty, min: p.minOrderQty, max: _max, onChanged: (v) => setState(() => _qty = v)),
                        const Spacer(),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('Total', style: TextStyle(fontSize: 12)),
                          Text(formatINR(p.bulkPrice * _qty), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: MmbColors.deepBlue)),
                        ]),
                      ]),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        for (final m in {1, 2, 5, 10})
                          if (p.minOrderQty * m <= _max)
                            ActionChip(label: Text('${p.minOrderQty * m}'), onPressed: () => setState(() => _qty = p.minOrderQty * m)),
                      ]),
                    ]),
                  ),
                ),
              const SizedBox(height: 14),
              const Text('Specifications', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              spec('Category', p.category),
              spec('Storage', p.storage),
              spec('RAM', p.ram),
              spec('Color', p.color),
              spec('Condition', p.condition.label),
              const SizedBox(height: 14),
              const Text('Description', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(p.description),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: MmbColors.deepBlue, child: Icon(Icons.storefront, color: Colors.white)),
                  title: Text(p.shopName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${p.sellerName}\n${[p.area, p.city].where((e) => e != null && e.isNotEmpty).join(', ')}'),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 90),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)]),
          child: Row(children: [
            IconButton.outlined(
              onPressed: () => _contact(() => Contact.call(p.contactNumber)),
              icon: const Icon(Icons.call),
              tooltip: 'Call seller',
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              style: IconButton.styleFrom(foregroundColor: MmbColors.success),
              onPressed: () => _contact(() => Contact.whatsapp(p.whatsappNumber, message: _message)),
              icon: const Icon(Icons.chat),
              tooltip: 'WhatsApp seller',
            ),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(onPressed: buyable ? _addToCart : null, icon: const Icon(Icons.add_shopping_cart), label: Text(buyable ? 'Add to cart' : 'Out of stock'))),
          ]),
        ),
      ),
    );
  }
}
