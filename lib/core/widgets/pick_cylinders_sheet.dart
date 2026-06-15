import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../services/inventory_service.dart';
import '../../services/order_service.dart';
import '../di/service_locator.dart';
import 'cylinder_scan_sheet.dart';

String _slotKey(String itemId, int slotIndex) => '$itemId:$slotIndex';

List<Map<String, dynamic>> _expandGasSlots(List<Map<String, dynamic>> items) {
  final slots = <Map<String, dynamic>>[];
  for (final item in items) {
    final itemId = item['id']?.toString() ?? '';
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    for (var slot = 0; slot < qty; slot++) {
      slots.add({
        'item': item,
        'itemId': itemId,
        'slotIndex': slot,
        'key': _slotKey(itemId, slot),
        'name': item['productName']?.toString() ??
            item['product']?['name']?.toString() ??
            'Product',
        'expectedSize': item['productCylinderSize']?.toString() ??
            item['product']?['cylinderSize']?.toString(),
        'expectedProductId': item['productId']?.toString(),
        'qty': qty,
      });
    }
  }
  return slots;
}

Future<({String email, String password})?> _showManagerOverrideDialog(
  BuildContext context, {
  required String expectedName,
  required String scannedName,
}) async {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  ({String email, String password})? credentials;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Brand mismatch'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ordered: $expectedName'),
            Text('Scanned: $scannedName'),
            const SizedBox(height: 12),
            const Text('Manager approval required (same size, different brand).'),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Manager email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Manager password'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final email = emailController.text.trim();
            final password = passwordController.text;
            if (email.isEmpty || password.isEmpty) return;
            try {
              await sl<AuthService>().verifyManager(email, password);
              credentials = (email: email, password: password);
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          },
          child: const Text('Approve'),
        ),
      ],
    ),
  );

  emailController.dispose();
  passwordController.dispose();
  return credentials;
}

/// Collects outbound cylinder scans and marks delivery PICKED_UP.
Future<bool> showPickCylindersSheet(
  BuildContext context, {
  required String deliveryId,
  required String orderId,
}) async {
  final order = await sl<OrderService>().getById(orderId);
  final items = (order['items'] as List<dynamic>? ?? [])
      .map((e) => e as Map<String, dynamic>)
      .where((item) {
        final type = item['itemType']?.toString().toUpperCase() ?? '';
        return type.isEmpty ||
            type == 'REFILL' ||
            type == 'NEW_CYLINDER' ||
            type == 'EXCHANGE';
      })
      .toList();

  if (items.isEmpty) {
    await sl<DeliveryService>().updateStatus(deliveryId, {
      'status': 'PICKED_UP',
    });
    return true;
  }

  final slots = _expandGasSlots(items);
  final serials = <String, String>{};
  final brandOverrides = <String>{};
  String? overrideEmail;
  String? overridePassword;
  var submitted = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pick cylinders',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...slots.map((slot) {
                    final key = slot['key'] as String;
                    final name = slot['name'] as String;
                    final qty = slot['qty'] as int;
                    final slotIndex = slot['slotIndex'] as int;
                    final label = qty > 1 ? '$name #${slotIndex + 1}' : name;
                    final isOverride = brandOverrides.contains(key);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(label),
                      subtitle: Text(
                        serials[key]?.isNotEmpty == true
                            ? '${serials[key]}${isOverride ? ' (override)' : ''}'
                            : 'Not scanned',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () async {
                          final code = await showCylinderScanSheet(context);
                          if (code == null || code.isEmpty) return;
                          try {
                            final response =
                                await sl<InventoryService>().lookupCylinder(code);
                            final cylinder =
                                response['cylinder'] as Map<String, dynamic>?;
                            final serial =
                                cylinder?['serialNumber']?.toString();
                            if (serial == null) return;

                            final expectedSize =
                                slot['expectedSize']?.toString();
                            final scannedSize =
                                cylinder?['productCylinderSize']?.toString();
                            if (expectedSize != null &&
                                scannedSize != null &&
                                expectedSize != scannedSize) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Wrong size: order needs $expectedSize, scanned $scannedSize',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            final expectedProductId =
                                slot['expectedProductId']?.toString();
                            final scannedProductId =
                                cylinder?['productId']?.toString();
                            if (expectedProductId != null &&
                                scannedProductId != null &&
                                expectedProductId != scannedProductId) {
                              final creds = await _showManagerOverrideDialog(
                                context,
                                expectedName: name,
                                scannedName: cylinder?['productName']?.toString() ??
                                    'Scanned cylinder',
                              );
                              if (creds == null) return;
                              brandOverrides.add(key);
                              overrideEmail = creds.email;
                              overridePassword = creds.password;
                            }

                            setState(() => serials[key] = serial);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: slots.every((slot) {
                          final key = slot['key'] as String;
                          return serials[key]?.isNotEmpty == true;
                        })
                        ? () async {
                            try {
                              final payload = <String, dynamic>{
                                'status': 'PICKED_UP',
                                'outboundSerials': serials,
                              };
                              if (brandOverrides.isNotEmpty &&
                                  overrideEmail != null &&
                                  overridePassword != null) {
                                payload['brandMismatchOverrides'] =
                                    brandOverrides.toList();
                                payload['overrideApproverEmail'] = overrideEmail;
                                payload['overrideApproverPassword'] =
                                    overridePassword;
                              }
                              await sl<DeliveryService>().updateStatus(
                                deliveryId,
                                payload,
                              );
                              submitted = true;
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          }
                        : null,
                    child: const Text('Confirm pick up'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  return submitted;
}
