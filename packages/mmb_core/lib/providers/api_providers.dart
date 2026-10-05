import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/api/api_client.dart';
import '../services/api/sse_client.dart';
import '../services/api_auth_repository.dart';
import '../services/api_cart_repository.dart';
import '../services/api_catalog_repository.dart';
import '../services/api_enquiry_repository.dart';
import '../services/api_favorites_repository.dart';
import '../services/api_order_repository.dart';

final apiClientProvider = Provider<MmbApiClient>((ref) {
  final client = MmbApiClient();
  ref.onDispose(() => client.close());
  return client;
});

final sseClientProvider = Provider<MmbSseClient>((ref) => MmbSseClient());

final apiAuthRepositoryProvider = Provider<ApiAuthRepository>(
  (ref) => ApiAuthRepository(ref.watch(apiClientProvider)),
);

final apiCatalogRepositoryProvider = Provider<ApiCatalogRepository>(
  (ref) => ApiCatalogRepository(
    ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
  ),
);

final apiCartRepositoryProvider = Provider<ApiCartRepository>(
  (ref) => ApiCartRepository(
    ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
  ),
);

final apiFavoritesRepositoryProvider = Provider<ApiFavoritesRepository>(
  (ref) => ApiFavoritesRepository(
    ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
  ),
);

final apiEnquiryRepositoryProvider = Provider<ApiEnquiryRepository>(
  (ref) => ApiEnquiryRepository(
    ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
  ),
);

final apiOrderRepositoryProvider = Provider<ApiOrderRepository>(
  (ref) => ApiOrderRepository(ref.watch(apiClientProvider)),
);

/// Exposes the live authenticated user via the REST API auth repository
final apiAuthStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(apiAuthRepositoryProvider);
  return repo.authStateChanges();
});

/// Exposes current profile
final apiCurrentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(apiAuthStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(apiAuthRepositoryProvider).userStream(user.uid);
});
