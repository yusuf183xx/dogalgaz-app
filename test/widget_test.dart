import 'package:flutter_test/flutter_test.dart';

import 'package:dogalgazz/main.dart';

void main() {
  test('service and trust content is populated', () {
    expect(services, isNotEmpty);
    expect(reasons, isNotEmpty);
    expect(
      services.any((service) => service.title == 'Doğalgaz Tesisatı'),
      isTrue,
    );
  });
}
