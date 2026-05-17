import '../models/quote_request.dart';

class QuoteSubmissionResult {
  const QuoteSubmissionResult({
    required this.storedInCloud,
    required this.userMessage,
    this.leadId,
  });

  final bool storedInCloud;
  final String userMessage;
  final String? leadId;
}

abstract class QuoteRepository {
  bool get cloudEnabled;
  String get statusTitle;
  String get statusDescription;

  Future<QuoteSubmissionResult> submitQuote(QuoteRequest request);
}

class PendingSetupQuoteRepository implements QuoteRepository {
  const PendingSetupQuoteRepository({this.reason});

  final String? reason;

  @override
  bool get cloudEnabled => false;

  @override
  String get statusTitle => 'Firebase beklemede';

  @override
  String get statusDescription =>
      'Teklif formu hazır, ancak Firestore bağlantısı için Firebase kurulumu tamamlanamadı. Kullanıcı yine de WhatsApp ile teklif gönderebilir.';

  @override
  Future<QuoteSubmissionResult> submitQuote(QuoteRequest request) async {
    return const QuoteSubmissionResult(
      storedInCloud: false,
      userMessage:
          'Firebase bağlantısı hazır olmadığı için teklif sadece WhatsApp akışına yönlendirildi.',
    );
  }
}
