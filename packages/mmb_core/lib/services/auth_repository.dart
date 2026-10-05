import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/enums.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authChanges() => _auth.authStateChanges();

  Stream<AppUser?> userStream(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(
            (s) => s.exists ? AppUser.fromMap({...s.data()!, 'uid': uid}) : null,
          );

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Creates the auth account and the profile document.
  /// Sellers start as `pending` (admin must approve); buyers are `approved`.
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? whatsapp,
    String? shopName,
    String? city,
    String? area,
  }) async {
    assert(role != UserRole.admin);
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = AppUser(
      uid: cred.user!.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      whatsapp: whatsapp?.trim(),
      shopName: shopName?.trim(),
      city: city?.trim(),
      area: area?.trim(),
      role: role,
      status: role == UserRole.seller ? ApprovalStatus.pending : ApprovalStatus.approved,
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  /// Only profile fields: security rules block changes to role/status.
  Future<void> updateProfile(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  Future<void> signOut() => _auth.signOut();

  static String message(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address looks wrong.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'This email is already registered. Try logging in.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a bit and try again.';
      }
    }
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'You do not have permission to do that.';
    }
    return 'Something went wrong. Please try again.';
  }
}
