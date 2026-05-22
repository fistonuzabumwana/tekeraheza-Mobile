import 'package:intl/intl.dart';

String formatCurrency(dynamic amount) {
  final n = amount is num
      ? amount.toDouble()
      : double.tryParse(amount?.toString() ?? '') ?? 0;
  return '${NumberFormat('#,###').format(n)} RWF';
}

String formatDate(dynamic date) {
  if (date == null) return '—';
  try {
    final dt = DateTime.parse(date.toString());
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  } catch (_) {
    return date.toString();
  }
}
