import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_app/models/item.dart';

void main() {
  group('Item model', () {
    test('toMap and fromMap round-trip', () {
      const original = Item(
        id: 'doc1',
        name: 'Test part',
        quantity: 12,
        price: 4.5,
      );
      final map = original.toMap();
      expect(map, {'name': 'Test part', 'quantity': 12, 'price': 4.5});
      final restored = Item.fromMap('doc1', map);
      expect(restored.id, 'doc1');
      expect(restored.name, original.name);
      expect(restored.quantity, original.quantity);
      expect(restored.price, original.price);
    });
  });
}
