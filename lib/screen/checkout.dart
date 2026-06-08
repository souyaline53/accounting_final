import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/accounting_models.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Product> products;
  // 戻り値として整理券番号(int)を期待するFuture関数に変更
  final Future<int> Function() onComplete;

  const CheckoutScreen({
    super.key,
    required this.products,
    required this.onComplete,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _receivedStr = "0";
  bool _isLoading = false;

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

  int get _receivedAmount => int.tryParse(_receivedStr) ?? 0;

  int get _changeAmount {
    if (_receivedAmount < _totalAmount) return 0;
    return _receivedAmount - _totalAmount;
  }

  void _onKeyTap(String key) {
    if (_isLoading) return;
    setState(() {
      if (key == "C") {
        _receivedStr = "0";
      } else if (key == "⌫") {
        _receivedStr = _receivedStr.length > 1 ? _receivedStr.substring(0, _receivedStr.length - 1) : "0";
      } else {
        _receivedStr = (_receivedStr == "0") ? key : (_receivedStr + key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###");

    return Scaffold(
      appBar: AppBar(title: const Text('お会計')),
      body: Stack(
        children: [
          Container(
            color: Colors.green.shade50,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                    ),
                    child: Column(
                      children: [
                        _amountRow("合計金額", "¥${currencyFormat.format(_totalAmount)}", Colors.green, 40),
                        const Divider(height: 40),
                        _amountRow("お預かり", "¥${currencyFormat.format(_receivedAmount)}", Colors.black87, 32),
                        _amountRow("お釣り", "¥${currencyFormat.format(_changeAmount)}", Colors.orange.shade800, 32),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3.0,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 1; i <= 9; i++) _keyButton(i.toString()),
                        _keyButton("0"),
                        _keyButton("00"),
                        _keyButton("⌫", color: Colors.grey.shade300),
                        _keyButton("C", color: Colors.red.shade50),
                        const SizedBox(),
                        GestureDetector(
                          onTap: (_receivedAmount >= _totalAmount && !_isLoading)
                              ? () async {
                            setState(() => _isLoading = true);



                            try {
                              // 会計確定と整理券番号の取得
                              int qNum = await widget.onComplete();

                              // 整理券番号ダイアログの表示
                              if (!mounted) return;
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('会計完了', textAlign: TextAlign.center),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('整理券番号'),
                                      Text('$qNum', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('OK'),
                                    )
                                  ],
                                ),
                              );
                              if (!mounted) return;
                              Navigator.pop(context); // レジ画面に戻る
                            } catch (e) {
                              debugPrint("Transaction Error: $e");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('エラーが発生しました。もう一度お試しください。')),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: (_receivedAmount >= _totalAmount && !_isLoading) ? Colors.green.shade700 : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Text('確定', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
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
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _keyButton(String label, {Color? color}) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: _isLoading ? null : () => _onKeyTap(label),
        borderRadius: BorderRadius.circular(8),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
