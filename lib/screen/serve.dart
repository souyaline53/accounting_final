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
    // 未提供のものを優先的に、新しい順にソート
    final sortedHistory = List<SaleRecord>.from(history)
      ..sort((a, b) {
        if (a.isServed == b.isServed) {
          return b.timestamp.compareTo(a.timestamp);
        }
        return a.isServed ? 1 : -1;
      });

    // 最大20件に制限
    final displayHistory = sortedHistory.take(20).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('提供管理')),
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
                            Text(
                              DateFormat('HH:mm').format(record.timestamp),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${record.queueNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: record.itemsSummary.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    item,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                )).toList(),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              record.isServed ? '未提供に戻す' : '提供完了にする',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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
