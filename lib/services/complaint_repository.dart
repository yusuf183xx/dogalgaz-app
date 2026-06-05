import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/complaint.dart';

class ComplaintRepository {
  ComplaintRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isReady => _firestore != null;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore!.collection('complaints');

  Stream<List<Complaint>> watchUserComplaints(String userId) {
    if (!isReady) {
      return Stream.value(const []);
    }
    return _collection.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final complaints =
            snapshot.docs.map(Complaint.fromDoc).toList(growable: false);
        complaints.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
        );
        return complaints;
      },
    );
  }

  Stream<List<Complaint>> watchAllComplaints({
    ComplaintStatus? statusFilter,
    String search = '',
  }) {
    if (!isReady) {
      return Stream.value(const []);
    }
    return _collection.snapshots().map((snapshot) {
      var complaints = snapshot.docs.map(Complaint.fromDoc).toList(growable: false);
      complaints.sort(
        (a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );

      if (statusFilter != null) {
        complaints =
            complaints.where((item) => item.status == statusFilter).toList();
      }

      final normalized = search.trim().toLowerCase();
      if (normalized.isEmpty) {
        return complaints;
      }

      return complaints
          .where(
            (complaint) =>
                complaint.userName.toLowerCase().contains(normalized) ||
                complaint.phone.contains(normalized) ||
                complaint.location.toLowerCase().contains(normalized) ||
                complaint.title.toLowerCase().contains(normalized) ||
                complaint.detectedIssue.toLowerCase().contains(normalized),
          )
          .toList(growable: false);
    });
  }

  Future<String> createComplaint(Complaint complaint) async {
    if (!isReady) {
      throw StateError('Firebase baglantisi hazir degil.');
    }
    final doc = _collection.doc();
    await doc.set({
      ...complaint.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateStatus({
    required String complaintId,
    required ComplaintStatus status,
    required String adminNote,
    String? pdfUrl,
    String? pdfName,
  }) async {
    await _collection.doc(complaintId).update({
      'status': status.name,
      'adminNote': adminNote,
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
      if (pdfName != null) 'pdfName': pdfName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<ComplaintStatus, int>> statusCounts() async {
    final snapshot = await _collection.get();
    final counts = {
      for (final status in ComplaintStatus.values) status: 0,
    };

    for (final doc in snapshot.docs) {
      final status = ComplaintStatusX.fromString(doc.data()['status'] as String?);
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }
}
