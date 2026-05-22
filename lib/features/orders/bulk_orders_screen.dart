import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mobile_shell.dart';
import '../../services/order_service.dart';

/// CSV columns: `customerId,productId,quantity[,paymentMethod][,orderType]`
/// Header row optional. Matches backend bulk create payload.
class BulkOrdersScreen extends StatefulWidget {
  const BulkOrdersScreen({super.key});

  @override
  State<BulkOrdersScreen> createState() => _BulkOrdersScreenState();
}

class _BulkOrdersScreenState extends State<BulkOrdersScreen> {
  bool _busy = false;
  String? _lastMessage;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) {
      setState(() => _lastMessage = 'Could not read file');
      return;
    }
    final text = String.fromCharCodes(bytes);
    final orders = _parseCsv(text);
    if (orders.isEmpty) {
      setState(() => _lastMessage = 'No valid rows (need customerId,productId,quantity)');
      return;
    }

    setState(() {
      _busy = true;
      _lastMessage = 'Uploading ${orders.length} orders…';
    });

    try {
      final res = await sl<OrderService>().createBulk(orders);
      setState(() {
        _busy = false;
        _lastMessage =
            'Done: ${res['successCount'] ?? res['success'] ?? 'ok'} rows';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _lastMessage = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _parseCsv(String raw) {
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return [];

    var start = 0;
    final first = _splitCsvLine(lines[0]).map((s) => s.toLowerCase()).toList();
    if (first.contains('customerid') && first.contains('productid')) {
      start = 1;
    }

    final out = <Map<String, dynamic>>[];
    for (var i = start; i < lines.length; i++) {
      final cols = _splitCsvLine(lines[i]);
      if (cols.length < 3) continue;
      final customerId = cols[0].trim();
      final productId = cols[1].trim();
      final qty = int.tryParse(cols[2].trim()) ?? 0;
      if (customerId.isEmpty || productId.isEmpty || qty < 1) continue;
      final payment = cols.length > 3 && cols[3].trim().isNotEmpty
          ? cols[3].trim().toUpperCase()
          : 'CASH';
      out.add({
        'customerId': customerId,
        'orderType': cols.length > 4 && cols[4].trim().isNotEmpty
            ? cols[4].trim().toUpperCase()
            : 'STANDARD',
        'items': [
          {'productId': productId, 'quantity': qty},
        ],
        'paymentMethod': payment,
        'isDelivery': true,
      });
    }
    return out;
  }

  List<String> _splitCsvLine(String line) {
    final parts = <String>[];
    final buf = StringBuffer();
    var inQ = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQ = !inQ;
      } else if ((c == ',' && !inQ)) {
        parts.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    parts.add(buf.toString());
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Bulk Orders',
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload a CSV file. Each row (after optional header) is one order:\n\n'
              'customerId,productId,quantity[,paymentMethod][,orderType]\n\n'
              'Example:\n'
              '550e8400-e29b-41d4-a716-446655440000,660e8400-e29b-41d4-a716-446655440001,2,MOBILE_MONEY,STANDARD',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _pickAndUpload,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_busy ? 'Processing…' : 'Choose CSV file'),
            ),
            if (_lastMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _lastMessage!,
                style: TextStyle(
                  color: _lastMessage!.contains('Done')
                      ? AppColors.success
                      : AppColors.foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
