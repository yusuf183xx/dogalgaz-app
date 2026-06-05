import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/complaint.dart';
import '../models/quote_lead.dart';

class QuoteLeadRepository {
  QuoteLeadRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isReady => _firestore != null;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore!.collection('quote_requests');

  Stream<List<QuoteLead>> watchAll({
    ComplaintStatus? statusFilter,
    String search = '',
  }) {
    if (!isReady) {
      return Stream.value(const []);
    }

    return _collection.snapshots().map((snapshot) {
      var leads = snapshot.docs.map(QuoteLead.fromDoc).toList(growable: false);
      leads.sort(
        (a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );

      if (statusFilter != null) {
        leads = leads.where((item) => item.status == statusFilter).toList();
      }

      final normalized = search.trim().toLowerCase();
      if (normalized.isEmpty) {
        return leads;
      }

      return leads
          .where(
            (lead) =>
                lead.fullName.toLowerCase().contains(normalized) ||
                lead.phone.contains(normalized) ||
                lead.location.toLowerCase().contains(normalized) ||
                lead.service.toLowerCase().contains(normalized),
          )
          .toList(growable: false);
    });
  }

  Stream<List<QuoteLead>> watchUserLeads(String userId) {
    if (!isReady) {
      return Stream.value(const []);
    }

    return _collection.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final leads = snapshot.docs.map(QuoteLead.fromDoc).toList(growable: false);
        leads.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
        );
        return leads;
      },
    );
  }

  Future<void> updateLead({
    required String leadId,
    required ComplaintStatus status,
    required String adminNote,
  }) async {
    if (!isReady) {
      throw StateError('Firebase baglantisi hazir degil.');
    }

    await _collection.doc(leadId).update({
      'status': status.name,
      'adminNote': adminNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
