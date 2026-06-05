import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/fault_detection.dart';
import '../../app/locations.dart';
import '../../app/services.dart';
import '../../app/theme.dart';
import '../../models/complaint.dart';
import '../../widgets/location_picker.dart';
import '../auth/email_verification_screen.dart';
import '../auth/login_screen.dart';
import 'my_complaints_screen.dart';

class FaultReportScreen extends StatefulWidget {
  const FaultReportScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<FaultReportScreen> createState() => _FaultReportScreenState();
}

class _FaultReportScreenState extends State<FaultReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedSymptoms = {};
  String _province = marasProvince;
  String _district = marasDistricts.first;
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  FaultDiagnosis get _diagnosis => diagnoseFault(_selectedSymptoms);

  Future<void> _submit() async {
    final user = widget.services.authService.currentUser;
    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginScreen(services: widget.services),
        ),
      );
      return;
    }

    if (!widget.services.authService.isEmailVerified) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(services: widget.services),
        ),
      );
      return;
    }

    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir belirti seçiniz.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final diagnosis = _diagnosis;
      final complaint = Complaint(
        id: '',
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: user.displayName ?? 'Kullanıcı',
        phone: _phoneController.text.trim(),
        location: formatLocation(_province, _district),
        title: 'Arıza: ${diagnosis.issue}',
        description: _descriptionController.text.trim(),
        detectedIssue: diagnosis.issue,
        recommendedService: diagnosis.service,
        symptoms: diagnosis.symptoms,
        status: ComplaintStatus.bekliyor,
        adminNote: '',
        pdfUrl: null,
        pdfName: null,
        createdAt: null,
        updatedAt: null,
      );

      await widget.services.complaintRepository.createComplaint(complaint);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şikayetiniz kaydedildi. Durumu takip edebilirsiniz.')),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MyComplaintsScreen(services: widget.services),
        ),
      );
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt hatası: ${error.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagnosis = _diagnosis;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arıza Tespiti',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: appPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Belirtileri seçin, sistem olası arızayı ve önerilen hizmeti çıkarsın.',
                  style: TextStyle(color: appMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: faultSymptoms.map((symptom) {
                    final selected = _selectedSymptoms.contains(symptom.id);
                    return FilterChip(
                      selected: selected,
                      avatar: Icon(symptom.icon, size: 18),
                      label: Text(symptom.label),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedSymptoms.add(symptom.id);
                          } else {
                            _selectedSymptoms.remove(symptom.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_selectedSymptoms.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tespit Sonucu',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text('Olası arıza: ${diagnosis.issue}'),
                  const SizedBox(height: 6),
                  Text('Önerilen hizmet: ${diagnosis.service}'),
                  const SizedBox(height: 6),
                  Text('Güven oranı: %${diagnosis.confidence}'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 10
                            ? 'Geçerli telefon giriniz.'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  LocationPicker(
                    province: _province,
                    district: _district,
                    onProvinceChanged: (value) => setState(() => _province = value),
                    onDistrictChanged: (value) => setState(() => _district = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Ek açıklama',
                      alignLabelWithHint: true,
                      hintText: 'Sorunun nasıl göründüğünü kısaca yazın...',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: appAccent,
                        foregroundColor: const Color(0xFF1F2019),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.report_outlined),
                      label: Text(
                        _submitting ? 'Gönderiliyor...' : 'Şikayeti Gönder',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MyComplaintsScreen(services: widget.services),
              ),
            );
          },
          icon: const Icon(Icons.list_alt_outlined),
          label: const Text('Şikayetlerimi Gör'),
        ),
      ],
    );
  }
}
