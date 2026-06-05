import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quote_request.dart';
import 'firebase_bootstrap.dart';
import 'quote_repository.dart';

class QuoteRepositoryFactory {
  static Future<QuoteRepository> create() async {
    try {
      final ready = await FirebaseBootstrap.ensureInitialized();
      if (!ready) {
        throw Exception('Firebase baslatilamadi');
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
      'status': 'bekliyor',
      'adminNote': '',
      'source': 'flutter_app',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return QuoteSubmissionResult(
      storedInCloud: true,
      leadId: doc.id,
      userMessage:
          'Teklifiniz alındı. Admin ekibimiz inceleyip uygulama üzerinden cevap verecek.',
    );
  }
}
