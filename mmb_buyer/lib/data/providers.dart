import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import 'repositories.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiCatalogRepositoryProvider)),
);

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final apiRepo = ref.watch(apiCartRepositoryProvider);
  apiRepo.setProductsProvider(() => ref.watch(approvedProductsProvider).valueOrNull ?? const []);
  return CartRepository(apiRepo);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(apiFavoritesRepositoryProvider)),
);

final enquiryRepositoryProvider = Provider<EnquiryRepository>(
  (ref) => EnquiryRepository(ref.watch(apiEnquiryRepositoryProvider)),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(apiOrderRepositoryProvider)),
);

final _uidProvider = Provider<String?>((ref) => ref.watch(authStateProvider).valueOrNull?.uid);

/// Bottom navigation tab (0 Home, 1 Saved, 2 Cart, 3 Orders, 4 Profile).
final tabIndexProvider = StateProvider<int>((_) => 0);

final approvedProductsProvider = StreamProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchApproved(),
);

final bannersProvider = StreamProvider.autoDispose<List<BannerItem>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchBanners(),
);

final categoriesProvider = StreamProvider.autoDispose<List<String>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchCategories(),
);

final cartProvider = StreamProvider.autoDispose<List<CartItem>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(cartRepositoryProvider).watch(uid);
});

final favoriteIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return Stream.value(const {});
  return ref.watch(favoritesRepositoryProvider).watchIds(uid);
});

final myEnquiriesProvider = StreamProvider.autoDispose<List<Enquiry>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(enquiryRepositoryProvider).watchMine(uid);
});

final myOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).getOrders();
});
