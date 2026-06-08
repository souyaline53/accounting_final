import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/accounting_models.dart';

class ServeScreen extends StatelessWidget {
  final List<SaleRecord> history;

  const ServeScreen({super.key, required this.history});

  Future<void> _toggleServed(String id, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('history').doc(id).update({
      'isServed': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. 未提供 (isServed: false) を優先し、その中では古い順 (timestamp 昇順) にソート
    final sortedHistory = List<SaleRecord>.from(history)
      ..sort((a, b) {
        // 未提供 (false) を提供済み (true) より先に持ってくる
        if (a.isServed != b.isServed) {
          return a.isServed ? 1 : -1;
        }
        
        // isServed の状態が同じ場合
        if (!a.isServed) {
          // 未提供同士：timestamp が古い順（昇順）＝ 待たせている順
          return a.timestamp.compareTo(b.timestamp);
        } else {
          // 提供済み同士：timestamp が新しい順（降順）＝ 最近出した順
          return b.timestamp.compareTo(a.timestamp);
        }
      });

    // 2. 未提供の数をカウント
    final waitingCount = history.where((r) => !r.isServed).length;

    // 最大20件に制限
    final displayHistory = sortedHistory.take(20).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('提供管理'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '未提供: $waitingCount件',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: displayHistory.isEmpty
          ? const Center(child: Text('注文履歴がありません'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: displayHistory.length,
              itemBuilder: (context, index) {
                final record = displayHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: record.isServed ? Colors.grey.shade100 : Colors.white,
                  elevation: record.isServed ? 0 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: record.isServed ? Colors.transparent : Colors.green.shade200,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: record.isServed ? Colors.grey : Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                record.isServed ? '提供済み' : '未提供',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(DateFormat('HH:mm').format(record.timestamp)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green.shade700,
                              child: Text('${record.queueNumber}',
                                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: record.itemsSummary.map((item) => Text(item, style: const TextStyle(fontSize: 16))).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _toggleServed(record.id, record.isServed),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: record.isServed ? Colors.grey.shade300 : Colors.green,
                              foregroundColor: record.isServed ? Colors.black54 : Colors.white,
                            ),
                            child: Text(record.isServed ? '未提供に戻す' : '提供完了にする', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
