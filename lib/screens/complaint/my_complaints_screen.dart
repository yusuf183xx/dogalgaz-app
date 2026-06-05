import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../models/complaint.dart';
import '../../widgets/status_badge.dart';
import '../auth/email_verification_screen.dart';
import '../auth/login_screen.dart';

class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final user = services.authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Şikayetlerim')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Şikayetlerinizi görmek için giriş yapın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: appMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(services: services),
                      ),
                    );
                  },
                  child: const Text('Giriş Yap'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!services.authService.isEmailVerified) {
      return Scaffold(
        appBar: AppBar(title: const Text('Şikayetlerim')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'E-posta doğrulaması tamamlanmadan şikayet takibi açılmaz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: appMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EmailVerificationScreen(services: services),
                      ),
                    );
                  },
                  child: const Text('E-postayı Doğrula'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Şikayetlerim')),
      body: StreamBuilder<List<Complaint>>(
        stream: services.complaintRepository.watchUserComplaints(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return const Center(
              child: Text(
                'Henüz şikayet kaydınız yok.',
                style: TextStyle(color: appMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return ComplaintCard(complaint: complaints[index]);
            },
          );
        },
      ),
    );
  }
}

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({super.key, required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final dateText = complaint.createdAt != null
        ? DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(complaint.createdAt!)
        : 'Tarih bekleniyor';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    complaint.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusBadge(status: complaint.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(dateText, style: const TextStyle(color: appMuted, fontSize: 12)),
            const SizedBox(height: 10),
            Text('Tespit: ${complaint.detectedIssue}'),
            const SizedBox(height: 4),
            Text('Önerilen hizmet: ${complaint.recommendedService}'),
            if (complaint.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(complaint.description),
            ],
            if (complaint.adminNote.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x14103B2F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yönetici açıklaması',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      complaint.adminNote,
                      style: const TextStyle(color: appMuted, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
            if (complaint.pdfUrl != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(complaint.pdfUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(complaint.pdfName ?? 'PDF Raporu Aç'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
