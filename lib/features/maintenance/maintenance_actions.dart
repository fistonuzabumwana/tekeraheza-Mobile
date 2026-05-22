import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/user_role.dart';
import '../../services/inventory_service.dart';
import '../../services/maintenance_service.dart';

const maintenanceTypes = [
  'INSPECTION',
  'HYDROSTATIC_TEST',
  'VALVE_REPLACEMENT',
  'REFURBISHMENT',
  'REPAIR',
  'RECERTIFICATION',
  'CLEANING',
  'PAINTING',
  'CONDEMN',
];

const complianceTypes = [
  'VISUAL_INSPECTION',
  'SAFETY_VALVE_CHECK',
  'PRESSURE_RELIEF_TEST',
  'LEAK_TEST',
  'WEIGHT_VERIFICATION',
  'MARKING_VERIFICATION',
  'REGULATORY_CERTIFICATION',
];

const testResults = ['PASS', 'FAIL', 'CONDITIONAL_PASS'];

String _isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String _label(String raw) =>
    raw.replaceAll('_', ' ').toLowerCase().split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');

/// Schedule maintenance for a cylinder (`POST /maintenance`).
Future<bool?> showScheduleMaintenanceSheet(
  BuildContext context, {
  String? cylinderId,
  String? serialHint,
}) async {
  final serialCtrl = TextEditingController(text: serialHint ?? '');
  final notesCtrl = TextEditingController();
  var type = maintenanceTypes.first;
  var scheduled = DateTime.now().add(const Duration(days: 1));
  String? resolvedId = cylinderId;
  bool resolving = false;

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> resolveSerial() async {
            final sn = serialCtrl.text.trim();
            if (sn.isEmpty) return;
            setSheet(() => resolving = true);
            try {
              final c = await sl<InventoryService>().getCylinderBySerial(sn);
              setSheet(() {
                resolvedId = c['id']?.toString();
                resolving = false;
              });
            } catch (_) {
              setSheet(() {
                resolvedId = null;
                resolving = false;
              });
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Cylinder not found')),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Schedule maintenance',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (cylinderId == null) ...[
                    TextField(
                      controller: serialCtrl,
                      decoration: InputDecoration(
                        labelText: 'Serial number',
                        suffixIcon: IconButton(
                          icon: resolving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          onPressed: resolving ? null : resolveSerial,
                        ),
                      ),
                      onSubmitted: (_) => resolveSerial(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: maintenanceTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(_label(t)),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() => type = v ?? type),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Scheduled date'),
                    subtitle: Text(_isoDate(scheduled)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        initialDate: scheduled,
                      );
                      if (picked != null) {
                        setSheet(() => scheduled = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (resolvedId == null || resolvedId!.isEmpty) {
                        if (cylinderId == null) await resolveSerial();
                        if (resolvedId == null || resolvedId!.isEmpty) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Select a valid cylinder'),
                              ),
                            );
                          }
                          return;
                        }
                      }
                      try {
                        await sl<MaintenanceService>().scheduleMaintenance({
                          'cylinderId': resolvedId,
                          'maintenanceType': type,
                          'scheduledDate': _isoDate(scheduled),
                          if (notesCtrl.text.trim().isNotEmpty)
                            'notes': notesCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                    child: const Text('Schedule'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Record a safety compliance / inspection check (`POST /maintenance/compliance`).
Future<bool?> showRecordComplianceSheet(
  BuildContext context, {
  required String cylinderId,
}) async {
  var type = 'VISUAL_INSPECTION';
  var checkDate = DateTime.now();
  final notesCtrl = TextEditingController();
  final refCtrl = TextEditingController();

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Record inspection',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Check type'),
                    items: complianceTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(_label(t)),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() => type = v ?? type),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Check date'),
                    subtitle: Text(_isoDate(checkDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        initialDate: checkDate,
                      );
                      if (picked != null) {
                        setSheet(() => checkDate = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Regulatory reference (optional)',
                    ),
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await sl<MaintenanceService>().createComplianceCheck({
                          'cylinderId': cylinderId,
                          'complianceType': type,
                          'checkDate': _isoDate(checkDate),
                          if (refCtrl.text.trim().isNotEmpty)
                            'regulatoryReference': refCtrl.text.trim(),
                          if (notesCtrl.text.trim().isNotEmpty)
                            'notes': notesCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                    child: const Text('Submit check'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Complete in-progress maintenance (`POST /maintenance/{id}/complete`).
Future<bool?> showCompleteMaintenanceSheet(
  BuildContext context, {
  required String maintenanceId,
}) async {
  var result = 'PASS';
  var nextDate = DateTime.now().add(const Duration(days: 365));
  final findingsCtrl = TextEditingController();
  final actionsCtrl = TextEditingController();
  final certCtrl = TextEditingController();

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Complete maintenance',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: result,
                    decoration: const InputDecoration(labelText: 'Test result'),
                    items: testResults
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(_label(t)),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() => result = v ?? result),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Next inspection / maintenance'),
                    subtitle: Text(_isoDate(nextDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        initialDate: nextDate,
                      );
                      if (picked != null) {
                        setSheet(() => nextDate = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: findingsCtrl,
                    decoration: const InputDecoration(labelText: 'Findings'),
                    maxLines: 2,
                  ),
                  TextField(
                    controller: actionsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Actions taken',
                    ),
                    maxLines: 2,
                  ),
                  TextField(
                    controller: certCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Certificate number (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await sl<MaintenanceService>().completeMaintenance(
                          maintenanceId,
                          {
                            'testResult': result,
                            'nextMaintenanceDate': _isoDate(nextDate),
                            if (findingsCtrl.text.trim().isNotEmpty)
                              'findings': findingsCtrl.text.trim(),
                            if (actionsCtrl.text.trim().isNotEmpty)
                              'actionsTaken': actionsCtrl.text.trim(),
                            if (certCtrl.text.trim().isNotEmpty)
                              'certificateNumber': certCtrl.text.trim(),
                          },
                        );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                    child: const Text('Complete'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

bool canCompleteMaintenance(UserRole? role) =>
    role == UserRole.admin || role == UserRole.manager;

bool canScheduleMaintenance(UserRole? role) =>
    role == UserRole.admin ||
    role == UserRole.manager ||
    role == UserRole.staff;
