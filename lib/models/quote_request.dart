class QuoteRequest {
  const QuoteRequest({
    required this.fullName,
    required this.phone,
    required this.location,
    required this.service,
    required this.propertyType,
    required this.urgency,
    required this.contactPreference,
    required this.note,
    required this.submittedAt,
  });

  final String fullName;
  final String phone;
  final String location;
  final String service;
  final String propertyType;
  final String urgency;
  final String contactPreference;
  final String note;
  final DateTime submittedAt;

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'location': location,
      'service': service,
      'propertyType': propertyType,
      'urgency': urgency,
      'contactPreference': contactPreference,
      'note': note,
      'submittedAtIso': submittedAt.toIso8601String(),
      'searchKeywords': _searchKeywords,
    };
  }

  String toWhatsAppMessage({String? leadId, bool storedInCloud = false}) {
    final safeNote = note.trim().isEmpty ? 'Belirtilmedi' : note.trim();
    final cloudLine = storedInCloud
        ? 'Kayıt: Firestore talebi oluşturuldu'
        : 'Kayıt: Sadece WhatsApp üzerinden iletildi';

    final leadLine = leadId == null ? '' : '\nTalep Kimliği: $leadId';

    return '''
Merhaba Çamlı Doğalgaz,
uygulama üzerinden ön fiyat bilgisi almak istiyorum.

Ad Soyad: $fullName
Telefon: $phone
Konum: $location
Hizmet: $service
Mülk Tipi: $propertyType
Zamanlama: $urgency
İletişim Tercihi: $contactPreference
Not: $safeNote
$cloudLine$leadLine
''';
  }

  List<String> get _searchKeywords {
    return {
      fullName.toLowerCase(),
      phone.replaceAll(' ', ''),
      location.toLowerCase(),
      service.toLowerCase(),
      propertyType.toLowerCase(),
    }.toList();
  }
}
