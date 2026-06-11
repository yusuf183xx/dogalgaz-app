import 'package:cloud_firestore/cloud_firestore.dart';

class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.customerName,
    required this.service,
    required this.amount,
    required this.location,
    required this.note,
    required this.soldAt,
    required this.createdBy,
  });

  final String id;
  final String customerName;
  final String service;
  final double amount;
  final String location;
  final String note;
  final DateTime? soldAt;
  final String createdBy;

  factory SaleRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SaleRecord(
      id: doc.id,
      customerName: data['customerName'] as String? ?? '',
      service: data['service'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      location: data['location'] as String? ?? '',
      note: data['note'] as String? ?? '',
      soldAt: (data['soldAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'service': service,
      'amount': amount,
      'location': location,
      'note': note,
      'soldAt': soldAt != null
          ? Timestamp.fromDate(soldAt!)
          : FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'searchKeywords': [
        customerName.toLowerCase(),
        service.toLowerCase(),
        location.toLowerCase(),
      ],
    };
  }
}
