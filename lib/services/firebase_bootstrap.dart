import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  static Future<bool> ensureInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('Firebase initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
