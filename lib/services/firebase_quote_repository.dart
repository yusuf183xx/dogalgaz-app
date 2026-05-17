import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/quote_request.dart';
import 'quote_repository.dart';

class QuoteRepositoryFactory {
  static Future<QuoteRepository> create() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      return FirebaseQuoteRepository(FirebaseFirestore.instance);
    } catch (error) {
      return PendingSetupQuoteRepository(reason: error.toString());
    }
  }
}

class FirebaseQuoteRepository implements QuoteRepository {
  FirebaseQuoteRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  bool get cloudEnabled => true;

  @override
  String get statusTitle => 'Firebase aktif';

  @override
  String get statusDescription =>
      'Bu uygulamadan gelen teklif talepleri Firestore üzerinde quote_requests koleksiyonuna otomatik kaydedilir.';

  @override
  Future<QuoteSubmissionResult> submitQuote(QuoteRequest request) async {
    final doc = _firestore.collection('quote_requests').doc();

    await doc.set({
      ...request.toMap(),
      'leadId': doc.id,
      'status': 'new',
      'source': 'flutter_app',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return QuoteSubmissionResult(
      storedInCloud: true,
      leadId: doc.id,
      userMessage:
          'Teklif Firestore kaydına da düşürüldü. Talep Kimliği: ${doc.id}',
    );
  }
}
