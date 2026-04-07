/// inventory row stored in Firestore collection `items`.
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  /// empty id is used only before `add`; Firestore assigns the document id.
  final String id;
  final String name;
  final int quantity;
  final double price;

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'price': price,
      };

  factory Item.fromMap(String id, Map<String, dynamic> data) {
    final q = data['quantity'];
    final p = data['price'];
    return Item(
      id: id,
      name: (data['name'] ?? '').toString(),
      quantity: q is int
          ? q
          : q is num
              ? q.toInt()
              : int.tryParse('$q') ?? 0,
      price: p is double
          ? p
          : p is num
              ? p.toDouble()
              : double.tryParse('$p') ?? 0.0,
    );
  }

  Item copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}
