class Product {
  String name;
  int price;
  int currentOrderCount;

  Product({
    required this.name,
    required this.price,
    this.currentOrderCount = 0,
  });
}
