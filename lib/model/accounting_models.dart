import 'package:cloud_firestore/cloud_firestore.dart';

class Topping {
  String name;
  int price;
  int currentOrderCount; // UI上での個数保持用

  Topping({
    required this.name,
    required this.price,
    this.currentOrderCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }

  factory Topping.fromMap(Map<String, dynamic> map) {
    return Topping(
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
    );
  }
}

class Product {
  String id;
  String name;
  int price;
  int currentOrderCount; // 商品自体の注文数
  List<Topping> toppings;

  Product({
    this.id = '',
    required this.name,
    required this.price,
    this.currentOrderCount = 0,
    this.toppings = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'toppings': toppings.map((t) => t.toMap()).toList(),
    };
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    var toppingsData = data['toppings'] as List<dynamic>?;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      toppings: toppingsData != null
          ? toppingsData.map((t) => Topping.fromMap(Map<String, dynamic>.from(t))).toList()
          : [],
    );
  }
}

class SaleRecord {
  final String id;
  final DateTime timestamp;
  final List<String> itemsSummary;
  final int totalAmount;
  final int queueNumber;
  final bool isServed; // 提供状況を追加

  SaleRecord({
    required this.id,
    required this.timestamp,
    required this.itemsSummary,
    required this.totalAmount,
    required this.queueNumber,
    required this.isServed,
  });

  factory SaleRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SaleRecord(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      itemsSummary: List<String>.from(data['itemsSummary'] ?? []),
      totalAmount: data['totalAmount'] ?? 0,
      queueNumber: data['queueNumber'] ?? 0,
      isServed: data['isServed'] ?? false,
    );
  }
}
