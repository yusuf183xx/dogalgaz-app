import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sale_record.dart';

class SaleRepository {
  SaleRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isReady => _firestore != null;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore!.collection('sales');

  Stream<List<SaleRecord>> watchSales({String search = ''}) {
    if (!isReady) {
      return Stream.value(const []);
    }
    return _collection.snapshots().map((snapshot) {
      final sales = snapshot.docs.map(SaleRecord.fromDoc).toList(growable: false);
      sales.sort(
        (a, b) => (b.soldAt ?? DateTime(0)).compareTo(a.soldAt ?? DateTime(0)),
      );
      final normalized = search.trim().toLowerCase();
      if (normalized.isEmpty) {
        return sales;
      }

      return sales
          .where(
            (sale) =>
                sale.customerName.toLowerCase().contains(normalized) ||
                sale.service.toLowerCase().contains(normalized) ||
                sale.location.toLowerCase().contains(normalized),
          )
          .toList(growable: false);
    });
  }

  Future<void> addSale(SaleRecord sale) async {
    if (!isReady) {
      throw StateError('Firebase baglantisi hazir degil.');
    }
    await _collection.add(sale.toMap());
  }

  Future<Map<String, double>> salesByService() async {
    if (!isReady) {
      return {};
    }
    final snapshot = await _collection.get();
    final totals = <String, double>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final service = data['service'] as String? ?? 'Diğer';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      totals[service] = (totals[service] ?? 0) + amount;
    }

    return totals;
  }

  Future<double> totalRevenue() async {
    if (!isReady) {
      return 0;
    }
    final snapshot = await _collection.get();
    var total = 0.0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }
}
