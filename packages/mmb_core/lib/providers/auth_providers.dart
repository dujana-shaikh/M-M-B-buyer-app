import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/api_auth_repository.dart';
import 'api_providers.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

/// Primary AuthRepository backed by the REST API backend (/api/auth/...)
final authRepositoryProvider = Provider<ApiAuthRepository>(
  (ref) => ref.watch(apiAuthRepositoryProvider),
);

/// Live stream of authenticated user (null while logged out)
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Live profile of the logged-in user (null while signed out).
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).userStream(user.uid);
});
