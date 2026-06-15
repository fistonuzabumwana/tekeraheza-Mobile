/// Normalizes raw scan input from QR codes or manual entry.
String normalizeScanInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('{')) {
    try {
      // Minimal JSON parse without dart:convert dependency at call sites
      final serialMatch = RegExp(r'"serial"\s*:\s*"([^"]+)"').firstMatch(trimmed);
      if (serialMatch != null) return serialMatch.group(1)!.trim();
      final serialNumberMatch =
          RegExp(r'"serialNumber"\s*:\s*"([^"]+)"').firstMatch(trimmed);
      if (serialNumberMatch != null) return serialNumberMatch.group(1)!.trim();
      final codeMatch = RegExp(r'"code"\s*:\s*"([^"]+)"').firstMatch(trimmed);
      if (codeMatch != null) return codeMatch.group(1)!.trim();
    } catch (_) {
      // fall through
    }
  }

  return trimmed;
}

bool isTekerahezaQrPayload(String code) => code.trim().startsWith('THZ|');
