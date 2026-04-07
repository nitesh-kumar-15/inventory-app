import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';

/// Firestore API for inventory items. Widgets should call this layer only.
class InventoryService {
  InventoryService({FirebaseFirestore? firestore})
      : _items = (firestore ?? FirebaseFirestore.instance).collection('items');

  final CollectionReference<Map<String, dynamic>> _items;

  Future<void> addItem(Item item) async {
    await _items.add(item.toMap());
  }

  Stream<List<Item>> streamItems() {
    return _items.snapshots().map(
          (snap) => snap.docs
              .map((d) => Item.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> updateItem(Item item) async {
    await _items.doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }
}
