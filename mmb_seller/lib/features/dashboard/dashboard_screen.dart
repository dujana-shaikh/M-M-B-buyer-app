import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/providers.dart';
import '../products/product_form_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.onViewProducts});
  final VoidCallback onViewProducts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final products = ref.watch(myProductsProvider);
    final enquiries = ref.watch(receivedEnquiriesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('MMB Seller')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MmbColors.orange,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: AsyncBody<List<Product>>(
        value: products,
        onRetry: () => ref.invalidate(myProductsProvider),
        data: (list) {
          final active = list.where((p) => p.status == ApprovalStatus.approved && p.stockStatus == StockStatus.inStock).length;
          final out = list.where((p) => p.stockStatus == StockStatus.outOfStock).length;
          final pending = list.where((p) => p.status == ApprovalStatus.pending).length;
          final newEnq = enquiries.where((e) => e.status == EnquiryStatus.newEnquiry).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [MmbColors.darkBlue, MmbColors.deepBlue]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hello, ${user?.name ?? ''} 👋', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(user?.shopName ?? '', style: const TextStyle(color: MmbColors.yellow, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _Stat('Total products', '${list.length}', Icons.inventory_2, MmbColors.deepBlue),
                  _Stat('Active', '$active', Icons.check_circle, MmbColors.success),
                  _Stat('Out of stock', '$out', Icons.remove_shopping_cart, MmbColors.danger),
                  _Stat('Awaiting approval', '$pending', Icons.hourglass_top, MmbColors.orange),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.mark_chat_unread, color: MmbColors.orange),
                  title: Text('$newEnq new enquiries'),
                  subtitle: const Text('From buyers interested in your products'),
                ),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const SizedBox(
                  height: 260,
                  child: EmptyState(icon: Icons.add_business, title: 'No products yet', message: 'Tap "Add product" to post your first item for bulk sale.'),
                )
              else
                TextButton(onPressed: onViewProducts, child: const Text('View all my products')),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ]),
          ]),
        ),
      );
}
