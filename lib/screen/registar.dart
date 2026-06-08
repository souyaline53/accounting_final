import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../model/accounting_models.dart';

class RegisterScreen extends StatefulWidget {
  final List<Product> products;
  final Future<int?> Function(List<Product>, {bool issueQueueNumber}) onComplete;

  const RegisterScreen({super.key, required this.products, required this.onComplete});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 商品IDごとの注文個数
  final Map<String, int> _orderCounts = {};
  // 商品IDごとのトッピング個数 (商品ID -> {トッピング名 -> 個数})
  final Map<String, Map<String, int>> _toppingCounts = {};

  // 待ち時間管理用のフラグ
  bool _isLoading = false;

  // オーディオプレイヤーのインスタンス
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  int get _totalAmount {
    int total = 0;
    for (var p in widget.products) {
      int count = _orderCounts[p.id] ?? 0;
      total += p.price * count;
      if (count > 0) {
        final tCounts = _toppingCounts[p.id] ?? {};
        for (var t in p.toppings) {
          total += t.price * (tCounts[t.name] ?? 0);
        }
      }
    }
    return total;
  }

  // チャイムを鳴らすメソッド
  Future<void> _playChime() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/chime.mp3'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  // 整理券番号を表示するダイアログ
  void _showQueueNumberDialog(int queueNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('注文完了', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('整理券番号', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              '$queueNumber',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text('お客様にお伝えください', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('閉じる', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleComplete({required bool issueQueueNumber}) async {
    if (_totalAmount <= 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderedItems = widget.products.where((p) => (_orderCounts[p.id] ?? 0) > 0).map((p) {
        return Product(
          id: p.id,
          name: p.name,
          price: p.price,
          category: p.category,
          currentOrderCount: _orderCounts[p.id]!,
          toppings: p.toppings
              .map((t) => Topping(
                  name: t.name,
                  price: t.price,
                  currentOrderCount: (_toppingCounts[p.id] ?? {})[t.name] ?? 0))
              .toList(),
        );
      }).toList();

      // 1. 注文確定処理を実行 (Firebase保存 & 整理券番号取得)
      final queueNumber = await widget.onComplete(orderedItems, issueQueueNumber: issueQueueNumber);

      // 2. チャイムを鳴らす
      await _playChime();

      // 3. 整理券番号を発行した場合はダイアログで表示
      if (mounted) {
        if (issueQueueNumber && queueNumber != null) {
          _showQueueNumberDialog(queueNumber);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('注文を完了しました（整理券なし）')),
          );
        }
      }

      // 4. 入力内容をリセット
      setState(() {
        _orderCounts.clear();
        _toppingCounts.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###");

    // カテゴリごとにグループ化
    final groupedProducts = <String, List<Product>>{};
    for (var p in widget.products) {
      groupedProducts.putIfAbsent(p.category, () => []).add(p);
    }
    final categories = groupedProducts.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('注文入力'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () => setState(() {
                      _orderCounts.clear();
                      _toppingCounts.clear();
                    }),
            tooltip: 'リセット',
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
              itemCount: categories.length,
              itemBuilder: (context, catIndex) {
                final category = categories[catIndex];
                final productsInCategory = groupedProducts[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(category, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    ),
                    ...productsInCategory.map((p) {
                      final count = _orderCounts[p.id] ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Text('¥${currencyFormat.format(p.price)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: _isLoading
                                        ? null
                                        : () => setState(() {
                                              if (count > 0) {
                                                _orderCounts[p.id] = count - 1;
                                                if (_orderCounts[p.id] == 0) _toppingCounts.remove(p.id);
                                              }
                                            }),
                                  ),
                                  Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green),
                                    onPressed: _isLoading ? null : () => setState(() => _orderCounts[p.id] = count + 1),
                                  ),
                                ],
                              ),
                            ),
                            if (p.toppings.isNotEmpty && count > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    ...p.toppings.map((t) {
                                      final tCounts = _toppingCounts[p.id] ?? {};
                                      final tCount = tCounts[t.name] ?? 0;
                                      return Row(
                                        children: [
                                          Expanded(child: Text('${t.name} (+¥${t.price})')),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                                            onPressed: _isLoading
                                                ? null
                                                : () => setState(() {
                                                      if (tCount > 0) _toppingCounts.putIfAbsent(p.id, () => {})[t.name] = tCount - 1;
                                                    }),
                                          ),
                                          Text('$tCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                                            onPressed: _isLoading
                                                ? null
                                                : () => setState(() => _toppingCounts.putIfAbsent(p.id, () => {})[t.name] = tCount + 1),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: OutlinedButton(
                          onPressed: (_totalAmount > 0 && !_isLoading)
                              ? () => _handleComplete(issueQueueNumber: false)
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.green.shade700, width: 2),
                            foregroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('整理券なし', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: (_totalAmount > 0 && !_isLoading)
                              ? () => _handleComplete(issueQueueNumber: true)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text('注文を確定する(整理券あり)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
