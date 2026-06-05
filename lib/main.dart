import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app/locations.dart';
import 'app/services.dart';
import 'app/theme.dart';
import 'models/quote_request.dart';
import 'services/admin_bootstrap.dart';
import 'services/quote_lead_repository.dart';
import 'widgets/location_picker.dart';
import 'screens/account/account_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/complaint/fault_report_screen.dart';
import 'services/auth_service.dart';
import 'services/complaint_repository.dart';
import 'services/firebase_bootstrap.dart';
import 'services/firebase_quote_repository.dart';
import 'services/quote_repository.dart';
import 'services/sale_repository.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.ensureInitialized();
  final quoteRepository = await QuoteRepositoryFactory.create();
  final firestore = firebaseReady ? FirebaseFirestore.instance : null;
  final auth = firebaseReady ? FirebaseAuth.instance : null;
  if (firebaseReady && auth != null && firestore != null) {
    await AdminBootstrap.ensureAdminAccount(auth: auth, firestore: firestore);
  }
  final services = AppServices(
    quoteRepository: quoteRepository,
    authService: AuthService(auth: auth, firestore: firestore),
    complaintRepository: ComplaintRepository(firestore: firestore),
    quoteLeadRepository: QuoteLeadRepository(firestore: firestore),
    saleRepository: SaleRepository(firestore: firestore),
    storageService: StorageService(
      storage: firebaseReady ? FirebaseStorage.instance : null,
    ),
  );
  runApp(CamliDogalgazApp(services: services));
}

class CamliDogalgazApp extends StatelessWidget {
  const CamliDogalgazApp({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Çamlı Doğalgaz',
      themeMode: ThemeMode.dark,
      theme: theme.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(theme.textTheme),
        appBarTheme: theme.appBarTheme.copyWith(
          titleTextStyle: GoogleFonts.manrope(
            color: const Color(0xFFE8F0EC),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      home: AppRoot(services: services),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: services.authService.authStateChanges,
      builder: (context, snapshot) {
        final user = services.authService.currentUser;
        if (user != null && !services.authService.isEmailVerified) {
          return EmailVerificationScreen(services: services);
        }
        return MainShell(services: services);
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ServicesScreen(),
      FaultReportScreen(services: widget.services),
      QuoteScreen(
        quoteRepository: widget.services.quoteRepository,
        services: widget.services,
      ),
      const TrustScreen(),
      AccountScreen(services: widget.services),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const BrandTitle(),
      ),
      body: Column(
        children: [
          if (!widget.services.authService.isReady)
            MaterialBanner(
              content: const Text(
                'Linux masaüstünde giriş ve takip için Chrome sürümünü kullanın.',
              ),
              leading: const Icon(Icons.info_outline, color: appBlue),
              actions: [
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.plumbing_outlined),
            selectedIcon: Icon(Icons.plumbing),
            label: 'Hizmetler',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle),
            label: 'Arıza',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote),
            label: 'Teklif',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Güven',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hesabım',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onNavigateToQuote,
  });

  final VoidCallback onNavigateToQuote;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeroPanel(),
          const SizedBox(height: 28),
          const SectionTitle(
            eyebrow: 'Hızlı Yönlendirme',
            title: 'Soruna göre doğru hizmeti daha hızlı bulun.',
            description:
                'Bu uygulama sadece vitrin değil. Kullanıcı sorununu daha hızlı anlatıp doğru hizmete yönlenebilsin diye tasarlandı.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                quickProblems
                    .map((problem) => ProblemCard(problem: problem))
                    .toList(),
          ),
          const SizedBox(height: 28),
          Row(
            children:
                stats
                    .map(
                      (stat) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: MetricCard(stat: stat),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 28),
          const SectionTitle(
            eyebrow: 'Öne Çıkan Hizmetler',
            title: 'En çok talep edilen hizmetler',
            description:
                'Doğalgaz tesisatı, kombi bakımı, petek temizliği ve toplu blok işlerinde mobilde daha net anlatım.',
          ),
          const SizedBox(height: 16),
          ...services.take(4).map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ServicePreviewCard(service: service),
                ),
              ),
          const SizedBox(height: 12),
          QuotePromptCard(onNavigateToQuote: onNavigateToQuote),
          const SizedBox(height: 28),
          const SectionTitle(
            eyebrow: 'Yorumlar',
            title: 'Memnun kalan müşterilerden geri bildirimler',
            description:
                'Yerinde hizmet verdiğin için güven ve düzen hissi uygulamanın da ana dili olmalı.',
          ),
          const SizedBox(height: 16),
          ...reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReviewCard(review: review),
                ),
              ),
        ],
      ),
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Hizmetler',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Maraş ve yakın illerde sunduğumuz hizmetler.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: appMuted),
        ),
        const SizedBox(height: 18),
        ...services.map(
          (service) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DetailedServiceCard(service: service),
          ),
        ),
      ],
    );
  }
}

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({
    super.key,
    required this.quoteRepository,
    required this.services,
  });

  final QuoteRepository quoteRepository;
  final AppServices services;

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _unitCountController = TextEditingController(text: '1');
  final _noteController = TextEditingController();

  String _service = services.first.title;
  String _propertyType = 'Daire';
  String _urgency = 'Bu hafta içinde';
  String _province = marasProvince;
  String _district = marasDistricts.first;
  bool _isSubmitting = false;

  bool get _showUnitCount =>
      requiresBulkUnits(
        province: _province,
        propertyType: _propertyType,
        service: _service,
      ) ||
      _propertyType == 'Apartman / blok' ||
      _service == 'Toplu Blok İşleri';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _unitCountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final unitCount = int.tryParse(_unitCountController.text.trim()) ?? 1;
    final bulkError = QuoteRequest.validateBulkRule(
      province: _province,
      propertyType: _propertyType,
      service: _service,
      unitCount: unitCount,
    );
    if (bulkError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bulkError)));
      return;
    }

    setState(() => _isSubmitting = true);

    final request = QuoteRequest(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      province: _province,
      district: _province == marasProvince ? _district : '',
      location: formatLocation(_province, _district),
      service: _service,
      propertyType: _propertyType,
      unitCount: unitCount,
      urgency: _urgency,
      note: _noteController.text.trim(),
      submittedAt: DateTime.now(),
      userId: widget.services.authService.currentUser?.uid ?? '',
    );

    final result = await widget.quoteRepository.submitQuote(request);

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.userMessage)),
    );
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teklif Talebi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Talebiniz admin paneline düşer, cevap uygulama üzerinden gelir.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: appMuted),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad soyad',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Ad soyad giriniz.' : null,
                  ),
                  const SizedBox(height: 12),
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
                  DropdownButtonFormField<String>(
                    initialValue: _service,
                    decoration: const InputDecoration(
                      labelText: 'Hizmet',
                      prefixIcon: Icon(Icons.handyman_outlined),
                    ),
                    items: services
                        .map(
                          (service) => DropdownMenuItem(
                            value: service.title,
                            child: Text(service.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _service = value ?? _service),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _propertyType,
                    decoration: const InputDecoration(
                      labelText: 'Mülk tipi',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Daire', child: Text('Daire')),
                      DropdownMenuItem(value: 'Müstakil ev', child: Text('Müstakil ev')),
                      DropdownMenuItem(value: 'Is yeri', child: Text('Is yeri')),
                      DropdownMenuItem(
                        value: 'Apartman / blok',
                        child: Text('Apartman / blok'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _propertyType = value ?? _propertyType),
                  ),
                  if (_showUnitCount) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _unitCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Daire / bölüm sayısı',
                        prefixIcon: const Icon(Icons.numbers_outlined),
                        helperText: isNearbyProvince(_province)
                            ? 'Yakın illerde minimum $minNearbyBulkUnits daire'
                            : null,
                      ),
                      validator: (value) {
                        final count = int.tryParse(value?.trim() ?? '');
                        if (count == null || count < 1) {
                          return 'Geçerli daire sayısı giriniz.';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _urgency,
                    decoration: const InputDecoration(
                      labelText: 'Zamanlama',
                      prefixIcon: Icon(Icons.schedule_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Bugün mümkünse', child: Text('Bugün mümkünse')),
                      DropdownMenuItem(value: 'Bu hafta içinde', child: Text('Bu hafta içinde')),
                      DropdownMenuItem(value: 'Bu ay içinde', child: Text('Bu ay içinde')),
                      DropdownMenuItem(
                        value: 'Sadece bilgi almak istiyorum',
                        child: Text('Sadece bilgi almak istiyorum'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _urgency = value ?? _urgency),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Ek not',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submitQuote,
                      style: FilledButton.styleFrom(
                        backgroundColor: appAccent,
                        foregroundColor: const Color(0xFF1F2019),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(_isSubmitting ? 'Gönderiliyor...' : 'Teklifi Gönder'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TrustScreen extends StatelessWidget {
  const TrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const IntroCard(
          eyebrow: 'Neden Biz?',
          title: 'Güven, tecrübe ve temiz işçiliği merkeze aldık.',
          description:
              'Site metinlerini koruduk ama mobilde bunu karar vermeyi kolaylaştıran kartlara dönüştürdük.',
        ),
        const SizedBox(height: 18),
        ...reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReasonCard(reason: reason),
              ),
            ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nasıl çalışıyoruz?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...processSteps.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ProcessTile(
                          stepNumber: entry.key + 1,
                          title: entry.value.title,
                          description: entry.value.description,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: appPrimary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_fire_department, color: appPrimary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Çamlı Doğalgaz',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Servis Uygulaması',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: appMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3026), Color(0xFF154E3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: appPrimary.withValues(alpha: 0.20),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Kahramanmaraş doğalgaz ustası',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ev ve iş yerleri için güven veren doğalgaz çözümleri.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '20 yılı aşkın tecrübe, temiz işçilik, toplu blok projeleri ve mobil teklif akışıyla daha kullanışlı bir uygulama.',
              style: TextStyle(
                color: Color(0xFFE7F1EC),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1600&q=80',
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => AppLauncher.call(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: appAccent,
                    foregroundColor: const Color(0xFF1F2019),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Hemen ara'),
                ),
                OutlinedButton.icon(
                  onPressed: () => AppLauncher.whatsApp(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('WhatsApp yaz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PresentationShowcaseCard extends StatelessWidget {
  const PresentationShowcaseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFF7FBF8), Color(0xFFEAF4EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: appPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppChip(text: 'Sunum İçin Hazır'),
          const SizedBox(height: 12),
          Text(
            'Şık tasarım, hızlı teklif akışı ve güven odaklı içerik tek uygulamada.',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Okul sunumunda hem tasarım tarafını hem de gerçek kullanım değerini gösterebilmen için uygulamayı daha güçlü bir vitrine çevirdik.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.6),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(
                child: ShowcaseMetric(
                  icon: Icons.design_services_outlined,
                  value: 'Modern',
                  label: 'Arayüz',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ShowcaseMetric(
                  icon: Icons.bolt_outlined,
                  value: 'Hızlı',
                  label: 'Teklif Akışı',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ShowcaseMetric(
                  icon: Icons.verified_outlined,
                  value: 'Güçlü',
                  label: 'Güven Hissi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShowcaseMetric extends StatelessWidget {
  const ShowcaseMetric({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: appBlue),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: appPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: appMuted),
          ),
        ],
      ),
    );
  }
}

class IntroCard extends StatelessWidget {
  const IntroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppChip(text: eyebrow),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppChip(text: eyebrow),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.6),
        ),
      ],
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: const Color(0x14103B2F),
      labelStyle: const TextStyle(
        color: appPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.stat});

  final QuickStat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: appPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stat.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProblemCard extends StatelessWidget {
  const ProblemCard({super.key, required this.problem});

  final ProblemSuggestion problem;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(problem.icon, color: appBlue),
              const SizedBox(height: 12),
              Text(
                problem.problem,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Önerilen hizmet: ${problem.service}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServicePreviewCard extends StatelessWidget {
  const ServicePreviewCard({super.key, required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0x141780CC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(service.icon, color: appPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.summary,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailedServiceCard extends StatelessWidget {
  const DetailedServiceCard({super.key, required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 88,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  appPrimary.withValues(alpha: 0.28),
                  appSurface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(service.icon, color: appPrimary, size: 36),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: appPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(service.icon, color: appPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  service.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.6),
                ),
                const SizedBox(height: 14),
                ...service.bullets.map(
                      (bullet) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(top: 7),
                              decoration: const BoxDecoration(
                                color: appAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bullet,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: appMuted, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuotePromptCard extends StatelessWidget {
  const QuotePromptCard({
    super.key,
    required this.onNavigateToQuote,
  });

  final VoidCallback onNavigateToQuote;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [appPrimary, Color(0xFF1A5F4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teklif akışı hazır',
              style: TextStyle(
                color: Color(0xFFFFE3B2),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Uygulamadaki form ile kullanıcıyı direkt düzenli bir iş talebine dönüştürüyoruz.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bu sayede fiyat al butonu sadece iletişime geç demiyor; hangi hizmet, hangi konum ve ne kadar aciliyet olduğunu da baştan topluyor.',
              style: TextStyle(color: Color(0xFFE7F1EC), height: 1.6),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onNavigateToQuote,
              style: FilledButton.styleFrom(
                backgroundColor: appAccent,
                foregroundColor: const Color(0xFF1F2019),
              ),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Teklif ekranına git'),
            ),
          ],
        ),
      ),
    );
  }
}

class FirebaseStatusCard extends StatelessWidget {
  const FirebaseStatusCard({
    super.key,
    required this.repository,
    this.lastLeadId,
    this.lastResultMessage,
  });

  final QuoteRepository repository;
  final String? lastLeadId;
  final String? lastResultMessage;

  @override
  Widget build(BuildContext context) {
    final background =
        repository.cloudEnabled
            ? const Color(0x141FA463)
            : const Color(0x14E8A33B);
    final accentColor = repository.cloudEnabled ? appWhatsApp : appAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  repository.cloudEnabled
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: accentColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    repository.statusTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                repository.statusDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.5),
              ),
            ),
            if (lastResultMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                lastResultMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.5),
              ),
            ],
            if (lastLeadId != null) ...[
              const SizedBox(height: 6),
              Text(
                'Son talep kimliği: $lastLeadId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: appPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final ReviewItem review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x14E8A33B),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '5.0',
                style: TextStyle(
                  color: Color(0xFF7A4A00),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              review.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              review.service,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: appMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpfulInfoCard extends StatelessWidget {
  const HelpfulInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tekliften önce neyi bilmek iyi olur?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ...const [
              'Kombi markası veya mevcut sistem bilgisi varsa not düşülmesi teklif sürecini hızlandırır.',
              'Apartman ve blok işlerinde daire sayısı veya proje tipi eklenirse daha net dönüş sağlanır.',
              'Petek temizliği ve bakım taleplerinde sorunun nasıl göründüğünü kısa anlatmak yeterlidir.',
            ].map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: appBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: appMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReasonCard extends StatelessWidget {
  const ReasonCard({super.key, required this.reason});

  final ReasonItem reason;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0x14103B2F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(reason.icon, color: appPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reason.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessTile extends StatelessWidget {
  const ProcessTile({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  final int stepNumber;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x141780CC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$stepNumber',
            style: const TextStyle(
              color: appBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: appMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AppLauncher {
  static Future<void> call(BuildContext context) {
    return _launch(
      context,
      Uri.parse('tel:${AppContact.phoneDisplay}'),
      errorMessage: 'Arama uygulaması açılamadı.',
    );
  }

  static Future<void> whatsApp(BuildContext context, {String? customMessage}) {
    final message = customMessage ?? 'Merhaba, uygulama üzerinden ulaşıyorum.';
    final uri = Uri.parse(
      'https://wa.me/${AppContact.whatsAppNumber}?text=${Uri.encodeComponent(message)}',
    );

    return _launch(
      context,
      uri,
      errorMessage: 'WhatsApp bağlantısı açılamadı.',
    );
  }

  static Future<void> _launch(
    BuildContext context,
    Uri uri, {
    required String errorMessage,
  }) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}

class AppContact {
  static const phoneDisplay = '05530545525';
  static const whatsAppNumber = '905530545525';
  static const logoUrl = 'https://yusuf183xx.github.io/dogalgaz-site/logo.png';
}

class QuickStat {
  const QuickStat({required this.value, required this.label});

  final String value;
  final String label;
}

class ProblemSuggestion {
  const ProblemSuggestion({
    required this.problem,
    required this.service,
    required this.icon,
  });

  final String problem;
  final String service;
  final IconData icon;
}

class ServiceItem {
  const ServiceItem({
    required this.title,
    required this.summary,
    required this.description,
    required this.imageUrl,
    required this.icon,
    required this.bullets,
  });

  final String title;
  final String summary;
  final String description;
  final String imageUrl;
  final IconData icon;
  final List<String> bullets;
}

class ReviewItem {
  const ReviewItem({
    required this.name,
    required this.service,
    required this.comment,
  });

  final String name;
  final String service;
  final String comment;
}

class ReasonItem {
  const ReasonItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class ProcessStep {
  const ProcessStep({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

const stats = [
  QuickStat(value: '20+ yıl', label: 'Saha tecrübesi'),
  QuickStat(value: 'Maraş + çevre', label: 'Hizmet bölgesi'),
  QuickStat(value: 'Blok işler', label: 'Toplu proje deneyimi'),
];

const quickProblems = [
  ProblemSuggestion(
    problem: 'Peteklerin altı soğuk kalıyor',
    service: 'Petek Temizligi',
    icon: Icons.thermostat_outlined,
  ),
  ProblemSuggestion(
    problem: 'Kombi kısa aralıklarla durup çalışıyor',
    service: 'Kombi Bakimi',
    icon: Icons.hvac_outlined,
  ),
  ProblemSuggestion(
    problem: 'Yeni daireye sıfır tesisat gerekiyor',
    service: 'Doğalgaz Tesisatı',
    icon: Icons.plumbing_outlined,
  ),
  ProblemSuggestion(
    problem: 'Apartmanda çoklu uygulama var',
    service: 'Toplu Blok İşleri',
    icon: Icons.apartment_rounded,
  ),
];

const services = [
  ServiceItem(
    title: 'Doğalgaz Tesisatı',
    summary: 'Daire içi hat çekimi, cihaz bağlantıları ve güvenli kurulum.',
    description:
        'Sıfırdan hat çekimi, daire içi düzenleme ve full tesisat akışına güvenlik, temiz görünüm ve uzun ömürlü kullanım açısından yaklaşır.',
    imageUrl:
        'https://images.pexels.com/photos/6419128/pexels-photo-6419128.jpeg?auto=compress&cs=tinysrgb&w=1200',
    icon: Icons.plumbing,
    bullets: [
      'Ana hat, cihaz hattı ve vana yerleşimini birlikte planlar.',
      'Mutfak, kombi ve petek bağlantılarını tek elden kurar.',
      'Temiz görünüm ile sonradan müdahalesi kolay bir akış hedefler.',
    ],
  ),
  ServiceItem(
    title: 'Kombi Bakımı',
    summary: 'Kış öncesi kontrol, performans takibi ve güvenli kullanım.',
    description:
        'Düzenli kombi bakımı performans kaybını azaltır, cihaz güvenliğini destekler ve soğuk sezonda sürpriz arıza riskini düşürür.',
    imageUrl:
        'https://images.pexels.com/photos/7859953/pexels-photo-7859953.jpeg?auto=compress&cs=tinysrgb&w=1200',
    icon: Icons.hvac,
    bullets: [
      'Kış öncesi temel kontrolleri düzenli şekilde yapar.',
      'Daha dengeli ısınma için cihaz durumunu gözden geçirir.',
      'Bakım sürecini teknik terime boğmadan anlatır.',
    ],
  ),
  ServiceItem(
    title: 'Petek Temizliği',
    summary: 'Daha dengeli ısınma ve daha rahat su dolaşımı için temizlik.',
    description:
        'Altı ısınmayan petekler, dengesiz ısı dağılımı ve düşük verim gibi sorunlarda profesyonel petek temizliği sistemi rahatlatır.',
    imageUrl:
        'https://images.pexels.com/photos/29226620/pexels-photo-29226620.jpeg?auto=compress&cs=tinysrgb&w=1200',
    icon: Icons.local_fire_department_outlined,
    bullets: [
      'Tortu ve çamurlaşma kaynaklı verim kaybına odaklanır.',
      'Sistem daha kısa sürede daha dengeli ısınmaya başlar.',
      'Gereksiz yakıt tüketimini azaltmaya yardımcı olur.',
    ],
  ),
  ServiceItem(
    title: 'Kombi Montajı ve Değişim',
    summary: 'Eski cihaz sökümü ve yeni kombi geçişini düzenli yönetir.',
    description:
        'Yeni cihaz kurulumu ve kombi değişiminde doğru bağlantı kurgusu, düzenli görünüm ve ileride kolay servis erişimi göz önünde tutulur.',
    imageUrl:
        'https://images.pexels.com/photos/34938439/pexels-photo-34938439.jpeg?auto=compress&cs=tinysrgb&w=1200',
    icon: Icons.settings_outlined,
    bullets: [
      'Eski cihaz sökümünden yeni geçişe kadar kontrollü süreç yürütür.',
      'Bağlantı noktalarını kullanım kolaylığı için konumlandırır.',
      'Alanı boğmayan temiz bir montaj hedefler.',
    ],
  ),
  ServiceItem(
    title: 'Yerden Isıtma',
    summary: 'Homojen ısı dağılımı ile konforlu ve estetik çözüm.',
    description:
        'Yeni projelerde ve kapsamlı tadilatlarda zeminden ısıtma sistemi ile daha sade görüntü ve dengeli ısı konforu sunulur.',
    imageUrl:
        'https://cdn.pixabay.com/photo/2018/11/14/07/23/underfloor-heating-3814621_1280.jpg',
    icon: Icons.grid_view_rounded,
    bullets: [
      'Yeni yaşam alanlarında dengeli ısı dağılımı kurar.',
      'Petek görünümü olmadan daha sade bir mekan hissi sağlar.',
      'Doğalgaz sistemiyle uyumlu uzun vadeli çözüm üretir.',
    ],
  ),
  ServiceItem(
    title: 'Toplu Blok İşleri',
    summary: 'Maraş ve yakın illerde çoklu konut projeleri.',
    description:
        'Kahramanmaraş genelinde tüm ilçelerde hizmet verilir. Gaziantep, Adıyaman, Malatya, Osmaniye, Kilis ve Hatay gibi yakın illerde toplu konut işleri kabul edilir.',
    imageUrl: '',
    icon: Icons.apartment,
    bullets: [
      'Maraş merkez ve tüm ilçelerde planlı uygulama.',
      'Yakın illerde yalnızca 5 daire ve üzeri toplu işler kabul edilir.',
      'Apartman, blok ve çoklu bağımsız bölüm projelerinde koordineli teslim.',
    ],
  ),
];

const reviews = [
  ReviewItem(
    name: 'Ahmet K.',
    service: 'Petek Temizliği',
    comment:
        'Petekler daha kısa sürede ısınmaya başladı. Düzenli çalıştılar ve ne yaptıklarını net anlattılar.',
  ),
  ReviewItem(
    name: 'Merve T.',
    service: 'Kombi Bakımı',
    comment:
        'Zamanında geldiler, kontrolleri aceleye getirmediler. Güven veren bir çalışma oldu.',
  ),
  ReviewItem(
    name: 'Yönetici Görüşü',
    service: 'Apartman ve Blok İşi',
    comment:
        'Toplu işlerde iletişim çok önemliydi. Planlı ilerlediler ve teslim tarafı da gayet düzenliydi.',
  ),
];

const reasons = [
  ReasonItem(
    title: 'Kahramanmaraş saha deneyimi',
    description:
        'Bölgenin ihtiyaçlarını bilen, yerel sahada çok sayıda uygulama yapmış bir ekip yapısı.',
    icon: Icons.location_city_outlined,
  ),
  ReasonItem(
    title: 'Toplu blok işi disiplini',
    description:
        'Sadece tekil tamirat değil, çoklu bölüm projelerinde de organize ilerleyebilen çalışma düzeni.',
    icon: Icons.domain_add_outlined,
  ),
  ReasonItem(
    title: 'Temiz ve kontrollü işçilik',
    description:
        'İşi toparlayarak teslim eden, son görünümü ve güven hissini önemseyen saha yaklaşımı.',
    icon: Icons.clean_hands_outlined,
  ),
  ReasonItem(
    title: 'Net iletişim',
    description:
        'Teknik detayları sade anlatan, kullanıcıyı yormayan ama doğru yönlendiren bir iletişim dili.',
    icon: Icons.record_voice_over_outlined,
  ),
  ReasonItem(
    title: 'Uzun ömürlü kullanım odağı',
    description:
        'Sadece anlık çözüm değil, sonrasında da rahat ettirecek sistem kurulumunu hedefler.',
    icon: Icons.verified_outlined,
  ),
];

const processSteps = [
  ProcessStep(
    title: 'İhtiyacı dinliyoruz',
    description:
        'Önce alanı ve sorunu anlıyor, gereksiz işlem önermek yerine doğru hizmeti seçiyoruz.',
  ),
  ProcessStep(
    title: 'Uygun planı çıkarıyoruz',
    description:
        'Bakım, montaj veya proje akışına işin ölçeğine göre net bir çizgi veriyoruz.',
  ),
  ProcessStep(
    title: 'Düzenli uyguluyoruz',
    description:
        'Acele etmeden, güvenli kullanım ve temiz görünüm odağıyla sahada ilerliyoruz.',
  ),
  ProcessStep(
    title: 'Kontrollü teslim ediyoruz',
    description:
        'Yapılan işi sade dille anlatıp alanı düzenli şekilde teslim ediyoruz.',
  ),
];
