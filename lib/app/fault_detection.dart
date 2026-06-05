import 'package:flutter/material.dart';

class FaultSymptom {
  const FaultSymptom({
    required this.id,
    required this.label,
    required this.icon,
    required this.issue,
    required this.service,
    required this.weight,
  });

  final String id;
  final String label;
  final IconData icon;
  final String issue;
  final String service;
  final int weight;
}

class FaultDiagnosis {
  const FaultDiagnosis({
    required this.issue,
    required this.service,
    required this.confidence,
    required this.symptoms,
  });

  final String issue;
  final String service;
  final int confidence;
  final List<String> symptoms;
}

const faultSymptoms = [
  FaultSymptom(
    id: 'cold_radiator_bottom',
    label: 'Petek altı soğuk kalıyor',
    icon: Icons.thermostat_outlined,
    issue: 'Petek içinde tortu veya hava birikimi',
    service: 'Petek Temizliği',
    weight: 3,
  ),
  FaultSymptom(
    id: 'boiler_short_cycle',
    label: 'Kombi sık sık durup çalışıyor',
    icon: Icons.hvac_outlined,
    issue: 'Basınç düşüklüğü veya sensör arızası',
    service: 'Kombi Bakımı',
    weight: 3,
  ),
  FaultSymptom(
    id: 'no_hot_water',
    label: 'Sıcak su gelmiyor',
    icon: Icons.water_drop_outlined,
    issue: 'Üç yollu vana veya eşanjör sorunu',
    service: 'Kombi Bakımı',
    weight: 2,
  ),
  FaultSymptom(
    id: 'gas_smell',
    label: 'Gaz kokusu veya kaçak şüphesi',
    icon: Icons.warning_amber_rounded,
    issue: 'Acil gaz kaçağı kontrolü gerekli',
    service: 'Doğalgaz Tesisatı',
    weight: 5,
  ),
  FaultSymptom(
    id: 'error_code',
    label: 'Kombi ekranında hata kodu var',
    icon: Icons.error_outline,
    issue: 'Elektronik kart veya sensör hatası',
    service: 'Kombi Bakımı',
    weight: 2,
  ),
  FaultSymptom(
    id: 'new_install',
    label: 'Yeni dairede tesisat yok',
    icon: Icons.plumbing_outlined,
    issue: 'Sıfır tesisat kurulumu gerekli',
    service: 'Doğalgaz Tesisatı',
    weight: 4,
  ),
  FaultSymptom(
    id: 'old_boiler',
    label: 'Eski kombi değişecek',
    icon: Icons.settings_outlined,
    issue: 'Kombi montajı ve değişim süreci',
    service: 'Kombi Montajı ve Değişim',
    weight: 3,
  ),
  FaultSymptom(
    id: 'block_project',
    label: 'Apartmanda toplu iş var',
    icon: Icons.apartment_rounded,
    issue: 'Blok proje planlaması gerekli',
    service: 'Toplu Blok İşleri',
    weight: 4,
  ),
];

FaultDiagnosis diagnoseFault(Set<String> selectedSymptomIds) {
  if (selectedSymptomIds.isEmpty) {
    return const FaultDiagnosis(
      issue: 'Belirti seçilmedi',
      service: 'Genel kontrol',
      confidence: 0,
      symptoms: [],
    );
  }

  final selected = faultSymptoms
      .where((symptom) => selectedSymptomIds.contains(symptom.id))
      .toList();

  final issueScores = <String, int>{};
  final serviceScores = <String, int>{};

  for (final symptom in selected) {
    issueScores[symptom.issue] = (issueScores[symptom.issue] ?? 0) + symptom.weight;
    serviceScores[symptom.service] =
        (serviceScores[symptom.service] ?? 0) + symptom.weight;
  }

  final topIssue = issueScores.entries.reduce(
    (a, b) => a.value >= b.value ? a : b,
  );
  final topService = serviceScores.entries.reduce(
    (a, b) => a.value >= b.value ? a : b,
  );

  final maxWeight = selected.fold<int>(0, (sum, item) => sum + item.weight);
  final confidence = ((topIssue.value / maxWeight) * 100).round().clamp(0, 100);

  return FaultDiagnosis(
    issue: topIssue.key,
    service: topService.key,
    confidence: confidence,
    symptoms: selected.map((item) => item.label).toList(),
  );
}
