import '../app/locations.dart';

class QuoteRequest {
  const QuoteRequest({
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
    required this.submittedAt,
    this.userId = '',
  });

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
  final DateTime submittedAt;
  final String userId;

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'province': province,
      'district': district,
      'location': location,
      'service': service,
      'propertyType': propertyType,
      'unitCount': unitCount,
      'urgency': urgency,
      'note': note,
      'userId': userId,
      'submittedAtIso': submittedAt.toIso8601String(),
      'searchKeywords': _searchKeywords,
    };
  }

  List<String> get _searchKeywords {
    return {
      fullName.toLowerCase(),
      phone.replaceAll(' ', ''),
      province.toLowerCase(),
      district.toLowerCase(),
      location.toLowerCase(),
      service.toLowerCase(),
      propertyType.toLowerCase(),
    }.toList();
  }

  static String? validateBulkRule({
    required String province,
    required String propertyType,
    required String service,
    required int unitCount,
  }) {
    if (!requiresBulkUnits(
      province: province,
      propertyType: propertyType,
      service: service,
    )) {
      return null;
    }

    if (unitCount < minNearbyBulkUnits) {
      return 'Yakın illerde toplu işler için en az $minNearbyBulkUnits daire girilmelidir.';
    }
    return null;
  }
}
