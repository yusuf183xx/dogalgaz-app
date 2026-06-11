import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../models/quote_lead.dart';
import '../../widgets/status_badge.dart';

class MyQuotesScreen extends StatelessWidget {
  const MyQuotesScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final user = services.authService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Tekliflerinizi görmek için giriş yapın.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tekliflerim')),
      body: StreamBuilder<List<QuoteLead>>(
        stream: services.quoteLeadRepository.watchUserLeads(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final leads = snapshot.data ?? [];
          if (leads.isEmpty) {
            return const Center(
              child: Text(
                'Henüz teklif kaydınız yok.',
                style: TextStyle(color: appMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: leads.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lead = leads[index];
              final date = lead.createdAt != null
                  ? DateFormat(
                      'dd MMM yyyy HH:mm',
                      'tr_TR',
                    ).format(lead.createdAt!)
                  : '-';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.service,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          StatusBadge(status: lead.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('$date • ${lead.location}'),
                      const SizedBox(height: 8),
                      Text(
                        'Mülk: ${lead.propertyType} • ${lead.unitCount} birim',
                      ),
                      if (lead.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(lead.note),
                      ],
                      if (lead.adminNote.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: appPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin cevabı',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                lead.adminNote,
                                style: const TextStyle(
                                  color: appMuted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
