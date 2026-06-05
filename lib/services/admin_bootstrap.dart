import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app/admin_config.dart';

class AdminBootstrap {
  static Future<void> ensureAdminAccount({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: AdminConfig.email,
        password: AdminConfig.password,
      );
      final uid = credential.user!.uid;
      await credential.user?.updateDisplayName(AdminConfig.displayName);
      await _writeAdminDocs(firestore, uid);
      await auth.signOut();
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') {
        return;
      }

      final credential = await auth.signInWithEmailAndPassword(
        email: AdminConfig.email,
        password: AdminConfig.password,
      );
      await _writeAdminDocs(firestore, credential.user!.uid);
      await auth.signOut();
    }
  }

  static Future<void> _writeAdminDocs(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    await firestore.collection('admins').doc(uid).set({
      'email': AdminConfig.email,
      'displayName': AdminConfig.displayName,
      'role': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await firestore.collection('users').doc(uid).set({
      'fullName': AdminConfig.displayName,
      'email': AdminConfig.email,
      'role': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
