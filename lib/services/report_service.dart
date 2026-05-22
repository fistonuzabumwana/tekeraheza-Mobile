import '../core/api/api_client.dart';
import '../core/utils/file_share.dart';

import 'dart:typed_data';
import 'package:dio/dio.dart';

class ReportDownload {
  const ReportDownload({
    required this.filename,
    required this.bytes,
    required this.mimeType,
  });

  final String filename;
  final Uint8List bytes;
  final String mimeType;

  SharedFile toSharedFile() =>
      SharedFile(filename: filename, bytes: bytes, mimeType: mimeType);
}

class ReportService {
  ReportService(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> getDashboardStats() => _api.get(
        '/analytics/dashboard',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> getDailyRevenue(int days) => _api.get(
        '/analytics/revenue/daily',
        queryParameters: {'days': days},
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<List<Map<String, dynamic>>> getMonthlyRevenue(int months) => _api.get(
        '/analytics/revenue/monthly',
        queryParameters: {'months': months},
        fromJson: (json) =>
            (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );

  Future<Map<String, dynamic>> getInventoryReport() => _api.get(
        '/reports/inventory',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> getSalesReport(
    String startDate,
    String endDate,
  ) =>
      _api.get(
        '/reports/sales',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> getDeliveryReport(
    String startDate,
    String endDate, {
    bool includeDetails = false,
  }) =>
      _api.get(
        '/reports/delivery',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          'includeDetails': includeDetails,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> getPaymentReconciliation(
    String startDate,
    String endDate,
  ) =>
      _api.get(
        '/reports/payment-reconciliation',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<ReportDownload> downloadSalesExport(
    String format,
    String startDate,
    String endDate,
  ) =>
      _download(
        '/reports/sales/export/$format',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
        fallbackFilename:
            'sales-report.${_ext(format)}',
      );

  Future<ReportDownload> downloadDeliveryExport(
    String format,
    String startDate,
    String endDate, {
    bool includeDetails = false,
  }) =>
      _download(
        '/reports/delivery/export/$format',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          'includeDetails': includeDetails,
        },
        fallbackFilename:
            'delivery-report.${_ext(format)}',
      );

  Future<ReportDownload> downloadInventoryExport(String format) => _download(
        '/reports/inventory/export/$format',
        fallbackFilename: 'inventory-report.${_ext(format)}',
      );

  Future<ReportDownload> downloadPaymentReconciliationExport(
    String format,
    String startDate,
    String endDate,
  ) =>
      _download(
        '/reports/payment-reconciliation/export/$format',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
        fallbackFilename:
            'payment-reconciliation.${_ext(format)}',
      );

  static String _ext(String format) {
    final f = format.toUpperCase();
    if (f == 'PDF') return 'pdf';
    if (f == 'EXCEL') return 'xlsx';
    if (f == 'CSV') return 'csv';
    return f.toLowerCase();
  }

  static String _filenameFromContentDisposition(
    String? cd,
    String fallback,
  ) {
    if (cd == null || cd.isEmpty) return fallback;
    final utf8 = RegExp(r"filename\*=UTF-8''([^;\s]+)", caseSensitive: false)
        .firstMatch(cd);
    if (utf8 != null) {
      try {
        return Uri.decodeFull(utf8.group(1)!);
      } catch (_) {
        return utf8.group(1)!;
      }
    }
    final m = RegExp(r'filename="([^"]+)"', caseSensitive: false).firstMatch(cd) ??
        RegExp(r'filename=([^;\s]+)', caseSensitive: false).firstMatch(cd);
    return m?.group(1)?.replaceAll('"', '') ?? fallback;
  }

  Future<ReportDownload> _download(
    String path, {
    Map<String, dynamic>? queryParameters,
    required String fallbackFilename,
  }) async {
    final res = await _api.dio.get<List<int>>(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    );

    final contentType = (res.headers.value('content-type') ?? 'application/octet-stream');
    final cd = res.headers.value('content-disposition');
    final filename = _filenameFromContentDisposition(cd, fallbackFilename);
    final bytes = Uint8List.fromList(res.data ?? const <int>[]);

    return ReportDownload(filename: filename, bytes: bytes, mimeType: contentType);
  }
}
