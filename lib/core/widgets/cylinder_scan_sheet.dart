import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../qr/cylinder_qr.dart';

/// Bottom sheet with camera QR scanner; returns normalized scan code on success.
Future<String?> showCylinderScanSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      var handled = false;

      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.55,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Scan cylinder QR code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      if (handled) return;
                      final barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;
                      final raw = barcodes.first.rawValue;
                      if (raw == null || raw.trim().isEmpty) return;
                      handled = true;
                      controller.stop();
                      Navigator.pop(ctx, normalizeScanInput(raw));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}
