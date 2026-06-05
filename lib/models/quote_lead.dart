import 'package:cloud_firestore/cloud_firestore.dart';

import 'complaint.dart';

class QuoteLead {
  const QuoteLead({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.province,
    required this.district,
    required this.location,
    required this.service,
    required this.propertyType,
    required this.unitCount,
    required this.urgency,
    required this.note,
    required this.status,
    required this.adminNote,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String province;
  final String district;
  final String location;
  final String service;
  final String propertyType;
  final int unitCount;
  final String urgency;
  final String note;
  final ComplaintStatus status;
  final String adminNote;
  final String userId;
  final DateTime? createdAt;

  factory QuoteLead.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return QuoteLead(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      province: data['province'] as String? ?? '',
      district: data['district'] as String? ?? '',
      location: data['location'] as String? ?? '',
      service: data['service'] as String? ?? '',
      propertyType: data['propertyType'] as String? ?? '',
      unitCount: (data['unitCount'] as num?)?.toInt() ?? 1,
      urgency: data['urgency'] as String? ?? '',
      note: data['note'] as String? ?? '',
      status: _statusFromLegacy(data['status'] as String?),
      adminNote: data['adminNote'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static ComplaintStatus _statusFromLegacy(String? value) {
    if (value == 'new') {
      return ComplaintStatus.bekliyor;
    }
    return ComplaintStatusX.fromString(value);
  }
}
