import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  bool get isReady => _auth != null && _firestore != null;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? Stream.value(null);

  User? get currentUser => _auth?.currentUser;

  bool get isEmailVerified => _auth?.currentUser?.emailVerified ?? false;

  void _ensureReady() {
    if (!isReady) {
      throw FirebaseAuthException(
        code: 'firebase-not-ready',
        message: 'Firebase baglantisi hazir degil.',
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    _ensureReady();
    final credential = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user?.updateDisplayName(fullName.trim());
    await _firestore!.collection('users').doc(credential.user!.uid).set({
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'email': email.trim().toLowerCase(),
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await credential.user?.sendEmailVerification();
  }

  Future<void> signIn({required String email, required String password}) async {
    _ensureReady();
    await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<bool> isAdmin(String uid) async {
    _ensureReady();
    final adminDoc = await _firestore!.collection('admins').doc(uid).get();
    if (adminDoc.exists) {
      return true;
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['role'] == 'admin';
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }

  Future<void> sendVerificationEmail() async {
    _ensureReady();
    final user = _auth!.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _ensureReady();
    await _auth!.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> reloadUser() async {
    await _auth?.currentUser?.reload();
  }

  String? friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Bu e-posta zaten kayıtlı.';
      case 'invalid-email':
        return 'Geçerli bir e-posta giriniz.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı hesap bulunamadı.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Biraz bekleyin.';
      case 'firebase-not-ready':
        return 'Firebase bağlantısı hazır değil.';
      default:
        return error.message ?? 'Giriş işlemi başarısız oldu.';
    }
  }
}
