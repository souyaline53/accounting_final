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
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('合計金額', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('¥${currencyFormat.format(_totalAmount)}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final p = widget.products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text('¥${currencyFormat.format(p.price)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => setState(() => p.currentOrderCount > 0 ? p.currentOrderCount-- : null),
                            ),
                            Text('${p.currentOrderCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => setState(() => p.currentOrderCount++),
                            ),
                          ],
                        ),
                      ),
                      if (p.toppings.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Divider(height: 1),
                        ),
                        ...p.toppings.map((t) => ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(left: 32, right: 16),
                              title: Text(t.name),
                              subtitle: Text('+¥${t.price}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _totalAmount > 0
                    ? () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              products: widget.products,
                              onComplete: () => widget.onComplete(widget.products),
                            ),
                          ),
                        );
                        setState(() {}); // 戻ってきた時にリセット状態を反映
                      }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                child: const Text('お会計へ進む', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
