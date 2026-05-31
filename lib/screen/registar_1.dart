import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/accounting_models.dart';
import 'checkout.dart';

class RegisterScreen extends StatefulWidget {
  final List<Product> products;
  final Future<int> Function(List<Product>) onComplete;

  const RegisterScreen({super.key, required this.products, required this.onComplete});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int get _totalAmount {
    int total = 0;
    for (var p in widget.products) {
      total += p.price * p.currentOrderCount;
      for (var t in p.toppings) {
        total += t.price * t.currentOrderCount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###");

    return Scaffold(
      appBar: AppBar(
        title: const Text('注文入力'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                for (var p in widget.products) {
                  p.currentOrderCount = 0;
                  for (var t in p.toppings) {
                    t.currentOrderCount = 0;
                  }
                }
              });
            },
            tooltip: 'リセット',
          ),
        ],
      ),
      body: Column(
        children: [
          // 上部：合計金額表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(bottom: BorderSide(color: Colors.green.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('合計金額', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                Text(
                  '¥${currencyFormat.format(_totalAmount)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          // 中央：商品リスト
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final p = widget.products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        subtitle: Text('¥${currencyFormat.format(p.price)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => setState(() => p.currentOrderCount > 0 ? p.currentOrderCount-- : null),
                            ),
                            Container(
                              width: 45,
                              alignment: Alignment.center,
                              child: Text('${p.currentOrderCount}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                              ),
                            ),
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => setState(() => p.currentOrderCount++),
                            ),
                          ],
                        ),
                      ),
                      if (p.toppings.isNotEmpty && p.currentOrderCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('トッピング', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 8),
                              ...p.toppings.map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(t.name)),
                                    Text('¥${t.price}'),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                                      onPressed: () => setState(() => t.currentOrderCount > 0 ? t.currentOrderCount-- : null),
                                    ),
                                    Text('${t.currentOrderCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                                      onPressed: () => setState(() => t.currentOrderCount++),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 下部：次にボタン
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton(
                onPressed: _totalAmount > 0
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            products: widget.products,
                            onComplete: () async {
                              int qNum = await widget.onComplete(widget.products);
                              return qNum;
                            },
                          ),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    }
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('お会計へ進む', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
