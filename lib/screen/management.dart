import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../model/accounting_models.dart';

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

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      sheetObject.appendRow([
        TextCellValue('日時'),
        TextCellValue('内容'),
        TextCellValue('合計金額'),
      ]);

      for (var r in widget.history) {
        sheetObject.appendRow([
          TextCellValue(DateFormat('yyyy/MM/dd HH:mm:ss').format(r.timestamp)),
          TextCellValue(r.itemsSummary.join(', ')),
          IntCellValue(r.totalAmount),
        ]);
      }
      sheetObject.appendRow([
        TextCellValue(''),
        TextCellValue('累計総売上'),
        IntCellValue(_totalAmount)
      ]);

      if (kIsWeb) {
        final List<int>? fileBytes = excel.save();
        if (fileBytes != null) {
          final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final String fileName = '学祭売上履歴_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
          
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          
          html.Url.revokeObjectUrl(url);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Excelファイルをダウンロードしました。')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('出力に失敗しました: $e')),
        );
      }
    }
  }

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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'management_fab',
        onPressed: widget.history.isEmpty ? null : _exportToExcel,
        label: const Text('Excel出力'),
        icon: const Icon(Icons.description),
        backgroundColor: Colors.green.shade800,
      ),
    );
  }
}
