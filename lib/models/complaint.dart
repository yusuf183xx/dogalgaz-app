import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplaintStatus {
  bekliyor,
  inceleniyor,
  onaylandi,
  reddedildi,
  tamamlandi,
}

extension ComplaintStatusX on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.bekliyor:
        return 'Bekliyor';
      case ComplaintStatus.inceleniyor:
        return 'İnceleniyor';
      case ComplaintStatus.onaylandi:
        return 'Onaylandı';
      case ComplaintStatus.reddedildi:
        return 'Reddedildi';
      case ComplaintStatus.tamamlandi:
        return 'Tamamlandı';
    }
  }

  static ComplaintStatus fromString(String? value) {
    return ComplaintStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ComplaintStatus.bekliyor,
    );
  }
}

class Complaint {
  const Complaint({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.phone,
    required this.location,
    required this.title,
    required this.description,
    required this.detectedIssue,
    required this.recommendedService,
    required this.symptoms,
    required this.status,
    required this.adminNote,
    required this.pdfUrl,
    required this.pdfName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String phone;
  final String location;
  final String title;
  final String description;
  final String detectedIssue;
  final String recommendedService;
  final List<String> symptoms;
  final ComplaintStatus status;
  final String adminNote;
  final String? pdfUrl;
  final String? pdfName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Complaint.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Complaint(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      location: data['location'] as String? ?? '',
      title: data['title'] as String? ?? 'Arıza bildirimi',
      description: data['description'] as String? ?? '',
      detectedIssue: data['detectedIssue'] as String? ?? '',
      recommendedService: data['recommendedService'] as String? ?? '',
      symptoms: List<String>.from(data['symptoms'] as List? ?? []),
      status: ComplaintStatusX.fromString(data['status'] as String?),
      adminNote: data['adminNote'] as String? ?? '',
      pdfUrl: data['pdfUrl'] as String?,
      pdfName: data['pdfName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'phone': phone,
      'location': location,
      'title': title,
      'description': description,
      'detectedIssue': detectedIssue,
      'recommendedService': recommendedService,
      'symptoms': symptoms,
      'status': status.name,
      'adminNote': adminNote,
      'pdfUrl': pdfUrl,
      'pdfName': pdfName,
      'searchKeywords': [
        userName.toLowerCase(),
        phone.replaceAll(' ', ''),
        location.toLowerCase(),
        title.toLowerCase(),
        detectedIssue.toLowerCase(),
        recommendedService.toLowerCase(),
      ],
    };
  }
}
