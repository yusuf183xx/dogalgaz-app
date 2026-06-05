const marasProvince = 'Kahramanmaraş';

const marasDistricts = [
  'Afşin',
  'Andırın',
  'Çağlayancerit',
  'Dulkadiroğlu',
  'Ekinözü',
  'Elbistan',
  'Göksun',
  'Nurhak',
  'Onikişubat',
  'Pazarcık',
  'Türkoğlu',
];

const nearbyProvinces = [
  'Gaziantep',
  'Adıyaman',
  'Malatya',
  'Osmaniye',
  'Kilis',
  'Hatay',
];

const allProvinces = [marasProvince, ...nearbyProvinces];

const minNearbyBulkUnits = 5;

bool isNearbyProvince(String province) => nearbyProvinces.contains(province);

bool requiresBulkUnits({
  required String province,
  required String propertyType,
  required String service,
}) {
  if (!isNearbyProvince(province)) {
    return false;
  }
  return propertyType == 'Apartman / blok' ||
      service == 'Toplu Blok İşleri';
}

String formatLocation(String province, String district) {
  if (province == marasProvince) {
    return '$province / $district';
  }
  return province;
}
