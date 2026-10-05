import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/providers.dart';
import '../../widgets/product_card.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final products = ref.watch(approvedProductsProvider).valueOrNull ?? const <Product>[];

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: AsyncBody<List<CartItem>>(
        value: cart,
        onRetry: () => ref.invalidate(cartProvider),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add products with their bulk quantity to send an enquiry.',
              action: ElevatedButton(onPressed: () => ref.read(tabIndexProvider.notifier).state = 0, child: const Text('Browse products')),
            );
          }
          final total = items.fold<double>(0, (t, e) => t + e.lineTotal);
          return Column(children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  final live = products.where((p) => p.id == it.productId).firstOrNull;
                  final max = live == null ? it.quantity : (live.quantityAvailable < it.minOrderQty ? it.minOrderQty : live.quantityAvailable);
                  return Dismissible(
                    key: ValueKey(it.productId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: MmbColors.danger, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => ref.read(cartRepositoryProvider).remove(uid!, it.productId),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          SizedBox(width: 78, height: 78, child: MmbImage(it.imageUrl, radius: 12)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (it.variantLabel.isNotEmpty) Text(it.variantLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              Text('${formatINR(it.unitPrice)} × ${it.quantity}  (MOQ ${it.minOrderQty})', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(children: [
                                QtyStepper(value: it.quantity, min: it.minOrderQty, max: max, onChanged: (v) => ref.read(cartRepositoryProvider).setQty(uid!, it.productId, v)),
                                const Spacer(),
                                Text(formatINR(it.lineTotal), style: const TextStyle(fontWeight: FontWeight.w900, color: MmbColors.deepBlue)),
                              ]),
                            ]),
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => ref.read(cartRepositoryProvider).remove(uid!, it.productId)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)]),
              child: SafeArea(
                top: false,
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('${items.length} item${items.length == 1 ? '' : 's'}', style: TextStyle(color: Colors.grey.shade600)),
                    Text(formatINR(total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: MmbColors.deepBlue)),
                  ]),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutScreen(items: items))),
                      child: const Text('Send enquiry'),
                    ),
                  ),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
