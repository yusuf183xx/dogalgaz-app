import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../models/complaint.dart';
import '../../models/quote_lead.dart';
import '../../models/sale_record.dart';
import '../../widgets/chart_widgets.dart';
import '../../widgets/status_badge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tabIndex = 0;
  ComplaintStatus? _statusFilter;
  ComplaintStatus? _quoteStatusFilter;
  final _searchController = TextEditingController();
  final _quoteSearchController = TextEditingController();
  final _saleSearchController = TextEditingController();

  Map<ComplaintStatus, int> _statusCounts = {};
  Map<String, double> _salesByService = {};
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quoteSearchController.dispose();
    _saleSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    final counts = await widget.services.complaintRepository.statusCounts();
    final sales = await widget.services.saleRepository.salesByService();
    final revenue = await widget.services.saleRepository.totalRevenue();
    if (mounted) {
      setState(() {
        _statusCounts = counts;
        _salesByService = sales;
        _totalRevenue = revenue;
      });
    }
  }

  Future<void> _signOut() async {
    await widget.services.authService.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loadReportData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Çıkış',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Şikayet')),
                ButtonSegment(value: 1, label: Text('Teklif')),
                ButtonSegment(value: 2, label: Text('Satış')),
                ButtonSegment(value: 3, label: Text('Rapor')),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (value) {
                setState(() => _tabIndex = value.first);
              },
            ),
          ),
          Expanded(
            child: switch (_tabIndex) {
              0 => _ComplaintsTab(
                  services: widget.services,
                  statusFilter: _statusFilter,
                  searchController: _searchController,
                  onFilterChanged: (status) {
                    setState(() => _statusFilter = status);
                  },
                  onUpdated: _loadReportData,
                ),
              1 => _QuotesTab(
                  services: widget.services,
                  statusFilter: _quoteStatusFilter,
                  searchController: _quoteSearchController,
                  onFilterChanged: (status) {
                    setState(() => _quoteStatusFilter = status);
                  },
                ),
              2 => _SalesTab(
                  services: widget.services,
                  searchController: _saleSearchController,
                  onAdded: _loadReportData,
                ),
              _ => _ReportsTab(
                  statusCounts: _statusCounts,
                  salesByService: _salesByService,
                  totalRevenue: _totalRevenue,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _ComplaintsTab extends StatefulWidget {
  const _ComplaintsTab({
    required this.services,
    required this.statusFilter,
    required this.searchController,
    required this.onFilterChanged,
    required this.onUpdated,
  });

  final AppServices services;
  final ComplaintStatus? statusFilter;
  final TextEditingController searchController;
  final ValueChanged<ComplaintStatus?> onFilterChanged;
  final VoidCallback onUpdated;

  @override
  State<_ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<_ComplaintsTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: widget.searchController,
                decoration: const InputDecoration(
                  labelText: 'İsim, telefon, konum ara',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tümü'),
                      selected: widget.statusFilter == null,
                      onSelected: (_) => widget.onFilterChanged(null),
                    ),
                    const SizedBox(width: 8),
                    ...ComplaintStatus.values.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.label),
                          selected: widget.statusFilter == status,
                          onSelected: (_) => widget.onFilterChanged(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Complaint>>(
            stream: widget.services.complaintRepository.watchAllComplaints(
              statusFilter: widget.statusFilter,
              search: widget.searchController.text,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final complaints = snapshot.data ?? [];
              if (complaints.isEmpty) {
                return const Center(child: Text('Filtreye uygun şikayet yok.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: complaints.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _AdminComplaintCard(
                    services: widget.services,
                    complaint: complaints[index],
                    onUpdated: widget.onUpdated,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminComplaintCard extends StatefulWidget {
  const _AdminComplaintCard({
    required this.services,
    required this.complaint,
    required this.onUpdated,
  });

  final AppServices services;
  final Complaint complaint;
  final VoidCallback onUpdated;

  @override
  State<_AdminComplaintCard> createState() => _AdminComplaintCardState();
}

class _AdminComplaintCardState extends State<_AdminComplaintCard> {
  late ComplaintStatus _status;
  late final TextEditingController _noteController;
  bool _saving = false;
  String? _pdfUrl;
  String? _pdfName;

  @override
  void initState() {
    super.initState();
    _status = widget.complaint.status;
    _noteController = TextEditingController(text: widget.complaint.adminNote);
    _pdfUrl = widget.complaint.pdfUrl;
    _pdfName = widget.complaint.pdfName;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      final uploaded = await widget.services.storageService.uploadPdf(
        bytes: Uint8List.fromList(bytes),
        fileName: file.name,
        folder: 'complaint_reports/${widget.complaint.id}',
      );
      setState(() {
        _pdfUrl = uploaded.url;
        _pdfName = uploaded.name;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF yüklendi.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.services.complaintRepository.updateStatus(
        complaintId: widget.complaint.id,
        status: _status,
        adminNote: _noteController.text.trim(),
        pdfUrl: _pdfUrl,
        pdfName: _pdfName,
      );
      widget.onUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şikayet güncellendi.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final dateText = complaint.createdAt != null
        ? DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(complaint.createdAt!)
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
                    complaint.userName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                StatusBadge(status: complaint.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('$dateText • ${complaint.phone} • ${complaint.location}'),
            const SizedBox(height: 8),
            Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Tespit: ${complaint.detectedIssue}'),
            Text('Hizmet: ${complaint.recommendedService}'),
            if (complaint.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(complaint.description),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<ComplaintStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: ComplaintStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Müşteriye görünen açıklama',
                hintText: 'Reddedildi, beklemede, onaylandı gibi durumları açıklayın...',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _saving ? null : _uploadPdf,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('PDF Yükle'),
                ),
                if (_pdfUrl != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(_pdfUrl!)),
                    child: Text(_pdfName ?? 'PDF'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: appPrimary),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotesTab extends StatefulWidget {
  const _QuotesTab({
    required this.services,
    required this.statusFilter,
    required this.searchController,
    required this.onFilterChanged,
  });

  final AppServices services;
  final ComplaintStatus? statusFilter;
  final TextEditingController searchController;
  final ValueChanged<ComplaintStatus?> onFilterChanged;

  @override
  State<_QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<_QuotesTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: widget.searchController,
                decoration: const InputDecoration(
                  labelText: 'İsim, telefon, hizmet ara',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tümü'),
                      selected: widget.statusFilter == null,
                      onSelected: (_) => widget.onFilterChanged(null),
                    ),
                    const SizedBox(width: 8),
                    ...ComplaintStatus.values.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.label),
                          selected: widget.statusFilter == status,
                          onSelected: (_) => widget.onFilterChanged(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<QuoteLead>>(
            stream: widget.services.quoteLeadRepository.watchAll(
              statusFilter: widget.statusFilter,
              search: widget.searchController.text,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final leads = snapshot.data ?? [];
              if (leads.isEmpty) {
                return const Center(child: Text('Filtreye uygun teklif yok.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: leads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _AdminQuoteCard(
                    services: widget.services,
                    lead: leads[index],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminQuoteCard extends StatefulWidget {
  const _AdminQuoteCard({
    required this.services,
    required this.lead,
  });

  final AppServices services;
  final QuoteLead lead;

  @override
  State<_AdminQuoteCard> createState() => _AdminQuoteCardState();
}

class _AdminQuoteCardState extends State<_AdminQuoteCard> {
  late ComplaintStatus _status;
  late final TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.lead.status;
    _noteController = TextEditingController(text: widget.lead.adminNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.services.quoteLeadRepository.updateLead(
        leadId: widget.lead.id,
        status: _status,
        adminNote: _noteController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teklif güncellendi.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    final dateText = lead.createdAt != null
        ? DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(lead.createdAt!)
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
                    lead.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                StatusBadge(status: lead.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('$dateText • ${lead.phone} • ${lead.location}'),
            const SizedBox(height: 8),
            Text(lead.service, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${lead.propertyType} • ${lead.unitCount} birim • ${lead.urgency}'),
            if (lead.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(lead.note),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<ComplaintStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: ComplaintStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Müşteriye görünen cevap',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesTab extends StatefulWidget {
  const _SalesTab({
    required this.services,
    required this.searchController,
    required this.onAdded,
  });

  final AppServices services;
  final TextEditingController searchController;
  final VoidCallback onAdded;

  @override
  State<_SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<_SalesTab> {
  final _nameController = TextEditingController();
  final _serviceController = TextEditingController();
  final _amountController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _serviceController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addSale() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (_nameController.text.trim().isEmpty ||
        _serviceController.text.trim().isEmpty ||
        amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müşteri, hizmet ve tutar zorunlu.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = widget.services.authService.currentUser;
      await widget.services.saleRepository.addSale(
        SaleRecord(
          id: '',
          customerName: _nameController.text.trim(),
          service: _serviceController.text.trim(),
          amount: amount,
          location: _locationController.text.trim(),
          note: _noteController.text.trim(),
          soldAt: DateTime.now(),
          createdBy: user?.email ?? '',
        ),
      );
      _nameController.clear();
      _serviceController.clear();
      _amountController.clear();
      _locationController.clear();
      _noteController.clear();
      widget.onAdded();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satış kaydedildi.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: widget.searchController,
                  decoration: const InputDecoration(
                    labelText: 'Satış ara',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Müşteri adı'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _serviceController,
                  decoration: const InputDecoration(labelText: 'Hizmet'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tutar (TL)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Konum'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Not'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _addSale,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Satış Ekle'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<SaleRecord>>(
          stream: widget.services.saleRepository.watchSales(
            search: widget.searchController.text,
          ),
          builder: (context, snapshot) {
            final sales = snapshot.data ?? [];
            if (sales.isEmpty) {
              return const Text('Satış kaydı yok.');
            }

            return Column(
              children: sales
                  .map(
                    (sale) => Card(
                      child: ListTile(
                        title: Text(sale.customerName),
                        subtitle: Text(
                          '${sale.service} • ${sale.location}\n${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(sale.amount)}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({
    required this.statusCounts,
    required this.salesByService,
    required this.totalRevenue,
  });

  final Map<ComplaintStatus, int> statusCounts;
  final Map<String, double> salesByService;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Şikayet durum grafiği',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 12),
                StatusPieChart(counts: statusCounts),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: ComplaintStatus.values
                      .map(
                        (status) => Text(
                          '${status.label}: ${statusCounts[status] ?? 0}',
                          style: const TextStyle(color: appMuted),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hizmet bazlı satış grafiği',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toplam ciro: ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(totalRevenue)}',
                  style: const TextStyle(color: appMuted),
                ),
                const SizedBox(height: 12),
                ServiceBarChart(totals: salesByService),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
