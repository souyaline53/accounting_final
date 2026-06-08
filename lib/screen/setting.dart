import 'package:flutter/material.dart';
import '../model/accounting_models.dart';

class ProductSettingsScreen extends StatelessWidget {
  final List<Product> products;
  final Function(String, int, String, List<Topping>) onAdd;
  final Function(int) onRemove;

  const ProductSettingsScreen({super.key, required this.products, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品管理')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Card(
            child: ListTile(
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('[${p.category}] ¥${p.price} / トッピング: ${p.toppings.length}種'),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => onRemove(index)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'setting_fab',
        onPressed: () => _showAddDialog(context),
        label: const Text('商品を追加'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    List<Topping> tempToppings = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('商品登録'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '商品名')),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: '価格'), keyboardType: TextInputType.number),
                // ... ダイアログ内にカテゴリ入力用 TextField を追加
                TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'カテゴリ (例: メイン, 飲み物)')),
                const Divider(height: 30),
                const Text('トッピング設定', style: TextStyle(fontWeight: FontWeight.bold)),
                ...tempToppings.asMap().entries.map((entry) => Row(
                  children: [
                    Expanded(child: Text('${entry.value.name}(¥${entry.value.price})')),
                    IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setDialogState(() => tempToppings.removeAt(entry.key))),
                  ],
                )),
                TextButton.icon(
                  onPressed: () => _showAddToppingDialog(context, (t) => setDialogState(() => tempToppings.add(t))),
                  icon: const Icon(Icons.add),
                  label: const Text('トッピングを追加'),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  onAdd(
                      nameCtrl.text,
                      int.tryParse(priceCtrl.text) ?? 0,
                      categoryCtrl.text.isEmpty ? '未分類' : categoryCtrl.text,
                      tempToppings
                  );                  
                  Navigator.pop(ctx);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToppingDialog(BuildContext context, Function(Topping) onAdd) {
    final tNameCtrl = TextEditingController();
    final tPriceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('トッピング登録'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tNameCtrl, decoration: const InputDecoration(labelText: 'トッピング名')),
            TextField(controller: tPriceCtrl, decoration: const InputDecoration(labelText: '価格'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () {
            onAdd(Topping(name: tNameCtrl.text, price: int.tryParse(tPriceCtrl.text) ?? 0));
            Navigator.pop(ctx);
          }, child: const Text('追加'))
        ],
      ),
    );
  }
}