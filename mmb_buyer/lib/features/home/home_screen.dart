import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/product_card.dart';
import '../catalog/search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(approvedProductsProvider);
    final banners = ref.watch(bannersProvider).valueOrNull;
    final cats = ref.watch(categoriesProvider).valueOrNull;
    final categories = (cats == null || cats.isEmpty) ? defaultCategories : cats;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(approvedProductsProvider),
        child: CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 64,
            titleSpacing: 16,
            title: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: MmbColors.orange, borderRadius: BorderRadius.circular(8)),
                child: const Text('MMB', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen(autofocus: true))),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.search, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text('Search mobiles, laptops, brands...', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          SliverToBoxAdapter(child: _BannerCarousel(banners: (banners == null || banners.isEmpty) ? defaultBanners : banners)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 104,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final color = categoryColors[i % categoryColors.length];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(initialCategory: categories[i]))),
                    child: SizedBox(
                      width: 82,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                          child: Icon(categoryIcon(categories[i]), color: color, size: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(categories[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
          ...products.when(
            loading: () => [const SliverFillRemaining(hasScrollBody: false, child: LoadingView())],
            error: (_, __) => [SliverFillRemaining(hasScrollBody: false, child: ErrorView(onRetry: () => ref.invalidate(approvedProductsProvider)))],
            data: (list) {
              if (list.isEmpty) {
                return [const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.storefront_outlined, title: 'No products yet', message: 'New products from distributors will appear here soon.'))];
              }
              final newest = [...list]..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
              final featured = list.where((p) => p.featured).toList();
              final trending = (featured.isNotEmpty ? featured : newest).take(8).toList();
              return [
                _heading('🔥 Trending now'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: trending.length,
                      itemBuilder: (_, i) => SizedBox(width: 165, child: Padding(padding: const EdgeInsets.only(right: 12, bottom: 6), child: ProductCard(product: trending[i]))),
                    ),
                  ),
                ),
                _heading('All products'),
                SliverToBoxAdapter(child: ProductGrid(products: newest, shrink: true)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ];
            },
          ),
        ]),
      ),
    );
  }

  Widget _heading(String t) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
      );
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners});
  final List<BannerItem> banners;
  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients || widget.banners.length < 2) return;
      _controller.animateToPage((_page + 1) % widget.banners.length, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: b.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Stack(fit: StackFit.expand, children: [
                  if (b.imageUrl != null && b.imageUrl!.isNotEmpty) MmbImage(b.imageUrl),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(b.subtitle, style: const TextStyle(color: Colors.white70)),
                    ]),
                  ),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < widget.banners.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: i == _page ? MmbColors.orange : Colors.grey.shade400, borderRadius: BorderRadius.circular(3)),
            ),
        ]),
      ]);
}
