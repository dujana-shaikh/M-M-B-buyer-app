import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/providers.dart';
import '../../widgets/product_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteIdsProvider);
    final products = ref.watch(approvedProductsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Products')),
      body: AsyncBody<List<Product>>(
        value: products,
        onRetry: () => ref.invalidate(approvedProductsProvider),
        data: (all) {
          final saved = ids.valueOrNull ?? const <String>{};
          final list = all.where((p) => saved.contains(p.id)).toList();
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.favorite_border, title: 'Nothing saved yet', message: 'Tap the heart on any product to save it here.');
          }
          return ProductGrid(products: list);
        },
      ),
    );
  }
}
