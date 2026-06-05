import '../services/auth_service.dart';
import '../services/complaint_repository.dart';
import '../services/quote_lead_repository.dart';
import '../services/quote_repository.dart';
import '../services/sale_repository.dart';
import '../services/storage_service.dart';

class AppServices {
  const AppServices({
    required this.quoteRepository,
    required this.authService,
    required this.complaintRepository,
    required this.quoteLeadRepository,
    required this.saleRepository,
    required this.storageService,
  });

  final QuoteRepository quoteRepository;
  final AuthService authService;
  final ComplaintRepository complaintRepository;
  final QuoteLeadRepository quoteLeadRepository;
  final SaleRepository saleRepository;
  final StorageService storageService;
}
