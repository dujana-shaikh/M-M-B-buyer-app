import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmb_core/mmb_core.dart';
import 'repositories.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(
    ref.watch(apiCatalogRepositoryProvider),
    FirebaseStorage.instance,
  ),
);

final enquiryRepositoryProvider = Provider<EnquiryRepository>(
  (ref) => EnquiryRepository(ref.watch(apiEnquiryRepositoryProvider)),
);

final sellerOrderRepositoryProvider = Provider<SellerOrderRepository>(
  (ref) => SellerOrderRepository(ref.watch(apiOrderRepositoryProvider)),
);

/// ONLY the logged-in distributor's products, updated via SSE stream.
final myProductsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(productRepositoryProvider).watchMine(uid);
});

/// Real-time live enquiries received by this distributor.
final receivedEnquiriesProvider = StreamProvider.autoDispose<List<Enquiry>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(enquiryRepositoryProvider).watchReceived(uid);
});

/// Orders received on the platform.
final sellerOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) {
  return ref.watch(sellerOrderRepositoryProvider).getOrders();
});
