import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const AccountingApp());
}

class AccountingApp extends StatelessWidget {
  const AccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学祭レジアプリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green.shade700,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// 商品モデル
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

// 販売記録モデル
class SaleRecord {
  final String id;
  final DateTime timestamp;
  final List<String> itemsSummary;
  final int totalAmount;

  SaleRecord({
    required this.id,
    required this.timestamp,
    required this.itemsSummary,
    required this.totalAmount,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // 商品データ（マスター）
  final List<Product> _products = [
    Product(name: '冷麦坦々', price: 500),
    Product(name: '冷麦坦々セット割', price: 800),
    Product(name: 'お茶', price: 150),
  ];

  // 販売履歴
  final List<SaleRecord> _history = [];

  void _completeTransaction() {
    setState(() {
      List<String> items = [];
      int total = 0;
      for (var p in _products) {
        if (p.currentOrderCount > 0) {
          items.add('${p.name} x${p.currentOrderCount}');
          total += p.price * p.currentOrderCount;
          p.currentOrderCount = 0;
        }
      }

      if (items.isNotEmpty) {
        _history.insert(0, SaleRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          itemsSummary: items,
          totalAmount: total,
        ));
      }
    });
  }

  void _deleteRecord(String id) {
    setState(() {
      _history.removeWhere((r) => r.id == id);
    });
  }

  void _addProduct(String name, int price) {
    setState(() {
      _products.add(Product(name: name, price: price));
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      RegisterScreen(products: _products, onComplete: _completeTransaction),
      SalesHistoryScreen(history: _history, onDelete: _deleteRecord),
      ProductSettingsScreen(
        products: _products,
        onAdd: _addProduct,
        onRemove: _removeProduct,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.green.shade700,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'レジ'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '商品設定'),
        ],
      ),
    );
  }
}

// --- 1. レジ画面 (テンキー付き・コンパクト版) ---
class RegisterScreen extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onComplete;

  const RegisterScreen({super.key, required this.products, required this.onComplete});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _receivedStr = "0";

  int get _totalAmount {
    return widget.products.fold(0, (sum, p) => sum + (p.price * p.currentOrderCount));
  }

  int get _receivedAmount => int.tryParse(_receivedStr) ?? 0;

  int get _changeAmount {
    if (_receivedAmount < _totalAmount) return 0;
    return _receivedAmount - _totalAmount;
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == "C") {
        _receivedStr = "0";
      } else if (key == "⌫") {
        if (_receivedStr.length > 1) {
          _receivedStr = _receivedStr.substring(0, _receivedStr.length - 1);
        } else {
          _receivedStr = "0";
        }
      } else {
        if (_receivedStr == "0") {
          _receivedStr = key;
        } else {
          if (_receivedStr.length < 9) {
            _receivedStr += key;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###");

    return Scaffold(
      appBar: AppBar(title: const Text('レジ入力')),
      body: Row(
        children: [
          // 左側: 会計・テンキーエリア (幅をかなりコンパクトに: flex 3)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // 金額表示部
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)
                      ],
                    ),
                    child: Column(
                      children: [
                        _amountRow("合計", "¥${currencyFormat.format(_totalAmount)}", Colors.green, 20),
                        const Divider(height: 10),
                        _amountRow("預り", "¥${currencyFormat.format(_receivedAmount)}", Colors.black87, 16),
                        _amountRow("釣り", "¥${currencyFormat.format(_changeAmount)}", Colors.orange.shade800, 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // テンキー
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 3,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1.3,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (var i = 1; i <= 9; i++) _keyButton(i.toString(), fontSize: 16),
                            _keyButton("0", fontSize: 16),
                            _keyButton("00", fontSize: 14),
                            _keyButton("⌫", color: Colors.grey.shade200, fontSize: 12),
                            _keyButton("C", color: Colors.red.shade50, fontSize: 12),
                            const SizedBox(),
                            GestureDetector(
                              onTap: (_totalAmount > 0 && _receivedAmount >= _totalAmount)
                                  ? () {
                                      widget.onComplete();
                                      setState(() => _receivedStr = "0");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('会計完了！'), duration: Duration(seconds: 1)),
                                      );
                                    }
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: (_totalAmount > 0 && _receivedAmount >= _totalAmount) ? Colors.green.shade700 : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: const Text('確定', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 右側: 商品リスト (より広く: flex 7)
          Expanded(
            flex: 7,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final p = widget.products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Text('¥${currencyFormat.format(p.price)}', style: const TextStyle(fontSize: 15)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 24),
                          onPressed: () => setState(() => p.currentOrderCount > 0 ? p.currentOrderCount-- : null),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text('${p.currentOrderCount}', 
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 24),
                          onPressed: () => setState(() => p.currentOrderCount++),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value, Color color, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _keyButton(String label, {Color? color, double fontSize = 14}) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(4),
      elevation: 0.5,
      child: InkWell(
        onTap: () => _onKeyTap(label),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// --- 2. 売上履歴画面 ---
class SalesHistoryScreen extends StatefulWidget {
  final List<SaleRecord> history;
  final Function(String) onDelete;

  const SalesHistoryScreen({super.key, required this.history, required this.onDelete});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalAmount => widget.history.fold(0, (sum, r) => sum + r.totalAmount);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###");
    final totalCount = widget.history.length;
    final totalPages = (totalCount / _pageSize).ceil();
    final actualTotalPages = totalPages == 0 ? 1 : totalPages;

    final start = _currentPage * _pageSize;
    final end = (start + _pageSize > totalCount) ? totalCount : start + _pageSize;
    final pagedHistory = totalCount == 0 ? [] : widget.history.sublist(start, end);

    return Scaffold(
      appBar: AppBar(title: const Text('売上履歴')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade700,
            child: Column(
              children: [
                const Text('累計売上額', style: TextStyle(color: Colors.white70)),
                Text('¥${currencyFormat.format(_totalAmount)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null),
              Text('ページ ${_currentPage + 1} / $actualTotalPages'),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < actualTotalPages - 1 ? () => setState(() => _currentPage++) : null),
            ],
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pagedHistory.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final record = pagedHistory[index];
                return ListTile(
                  title: Text(record.itemsSummary.join(', ')),
                  subtitle: Text(DateFormat('HH:mm:ss').format(record.timestamp)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('¥${currencyFormat.format(record.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => widget.onDelete(record.id)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. 商品設定画面 ---
class ProductSettingsScreen extends StatelessWidget {
  final List<Product> products;
  final Function(String, int) onAdd;
  final Function(int) onRemove;

  const ProductSettingsScreen({super.key, required this.products, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品設定')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Card(
            child: ListTile(
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('¥${p.price}'),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => onRemove(index)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        label: const Text('商品を追加'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('商品追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '商品名')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: '価格'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              final price = int.tryParse(priceController.text) ?? 0;
              if (name.isNotEmpty && price > 0) {
                onAdd(name, price);
                Navigator.pop(ctx);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }
}
