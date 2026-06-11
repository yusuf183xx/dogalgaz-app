import 'package:flutter/material.dart';

import '../app/locations.dart';

class LocationPicker extends StatelessWidget {
  const LocationPicker({
    super.key,
    required this.province,
    required this.district,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
  });

  final String province;
  final String district;
  final ValueChanged<String> onProvinceChanged;
  final ValueChanged<String> onDistrictChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: province,
          decoration: const InputDecoration(
            labelText: 'İl',
            prefixIcon: Icon(Icons.map_outlined),
          ),
          items: allProvinces
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            onProvinceChanged(value);
            if (value == marasProvince && !marasDistricts.contains(district)) {
              onDistrictChanged(marasDistricts.first);
            }
          },
        ),
        if (province == marasProvince) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: marasDistricts.contains(district)
                ? district
                : marasDistricts.first,
            decoration: const InputDecoration(
              labelText: 'İlçe',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            items: marasDistricts
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onDistrictChanged(value);
              }
            },
          ),
        ],
        if (isNearbyProvince(province)) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Yakın illerde toplu konut işleri için en az $minNearbyBulkUnits daire kabul edilir.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}
