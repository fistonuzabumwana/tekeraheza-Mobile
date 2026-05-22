import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/paged_response.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_share.dart';
import '../../core/utils/format_utils.dart';
import '../../features/maintenance/maintenance_actions.dart';
import '../../services/maintenance_service.dart';
import '../../core/widgets/data_list_screen.dart';
import '../../core/widgets/list_tile_card.dart';
import '../../core/widgets/location_selector.dart';
import '../../core/widgets/mobile_shell.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/custom_report_service.dart';
import '../../services/customer_service.dart';
import '../../services/delivery_service.dart';
import '../../services/inventory_service.dart';
import '../../services/payment_service.dart';
import '../../services/permission_service.dart';
import '../../services/receipt_service.dart';
import '../../services/segment_service.dart';
import '../../services/settings_service.dart';
import '../../services/template_service.dart';
// ——— Auth ———

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.token});
  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text != _confirm.text) return;
    setState(() => _loading = true);
    try {
      await sl<AuthService>().resetPassword(
        token: widget.token ?? '',
        newPassword: _password.text,
        confirmPassword: _confirm.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset. Please sign in.')),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 12),
            TextField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyCodeScreen extends StatelessWidget {
  const VerifyCodeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Open the verification link sent to your email, or enter the token from the link in the web app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ——— Inventory ———

class CylinderDetailScreen extends StatefulWidget {
  const CylinderDetailScreen({super.key, required this.cylinderId});
  final String cylinderId;

  @override
  State<CylinderDetailScreen> createState() => _CylinderDetailScreenState();
}

class _CylinderDetailScreenState extends State<CylinderDetailScreen> {
  final _inv = sl<InventoryService>();
  final _maint = sl<MaintenanceService>();

  Map<String, dynamic>? _cylinder;
  List<Map<String, dynamic>> _maintenanceHistory = [];
  List<Map<String, dynamic>> _complianceHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _inv.getCylinderById(widget.cylinderId),
        _maint.getMaintenanceByCylinder(widget.cylinderId, size: 20),
        _maint.getComplianceByCylinder(widget.cylinderId, size: 20),
      ]);
      if (!mounted) return;
      setState(() {
        _cylinder = results[0] as Map<String, dynamic>;
        _maintenanceHistory =
            (results[1] as PagedResponse<Map<String, dynamic>>).content;
        _complianceHistory =
            (results[2] as PagedResponse<Map<String, dynamic>>).content;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load cylinder: $e')),
      );
    }
  }

  Future<void> _onMaintenanceAction(Map<String, dynamic> record) async {
    final role = context.read<AuthProvider>().user?.role;
    final status = record['status']?.toString();
    final id = record['id']?.toString();
    if (id == null) return;

    if (status == 'SCHEDULED' && canScheduleMaintenance(role)) {
      try {
        await _maint.startMaintenance(id);
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maintenance started')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        }
      }
      return;
    }

    if (status == 'IN_PROGRESS' && canCompleteMaintenance(role)) {
      final ok = await showCompleteMaintenanceSheet(
        context,
        maintenanceId: id,
      );
      if (ok == true) await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final c = _cylinder;

    return MobileShell(
      title: c?['serialNumber']?.toString() ?? 'Cylinder',
      showBack: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : c == null
              ? const Center(child: Text('Cylinder not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ListTileCard(
                        title: c['serialNumber']?.toString() ?? 'Cylinder',
                        subtitle: c['productName']?.toString(),
                        status: c['status']?.toString(),
                      ),
                      if (c['needsInspection'] == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: StatusBadge(
                            label: 'Inspection due',
                            status: 'PENDING',
                          ),
                        ),
                      if (c['isExpired'] == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: StatusBadge(
                            label: 'Expired',
                            status: 'FAILED',
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (canScheduleMaintenance(role)) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final ok =
                                      await showScheduleMaintenanceSheet(
                                    context,
                                    cylinderId: widget.cylinderId,
                                    serialHint:
                                        c['serialNumber']?.toString(),
                                  );
                                  if (ok == true) await _load();
                                },
                                icon: const Icon(Icons.build_outlined),
                                label: const Text('Schedule'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final ok = await showRecordComplianceSheet(
                                    context,
                                    cylinderId: widget.cylinderId,
                                  );
                                  if (ok == true) await _load();
                                },
                                icon: const Icon(Icons.fact_check_outlined),
                                label: const Text('Inspect'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Details',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _row('Status', c['status']),
                      _row('Product', c['productName']),
                      _row('Warehouse', c['warehouseName']),
                      _row('Customer', c['currentCustomerName']),
                      _row('Manufacture', c['manufactureDate']),
                      _row('Expiry', c['expiryDate']),
                      _row('Last inspection', c['lastInspectionDate']),
                      _row('Next inspection', c['nextInspectionDate']),
                      _row('Refill count', c['refillCount']),
                      _row('Tare weight', c['tareWeight']),
                      if (c['conditionNotes'] != null)
                        _row('Condition notes', c['conditionNotes']),
                      const SizedBox(height: 20),
                      Text(
                        'Maintenance history',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_maintenanceHistory.isEmpty)
                        Text(
                          'No maintenance records yet.',
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        )
                      else
                        ..._maintenanceHistory.map((m) {
                          final status = m['status']?.toString() ?? '';
                          final canAct = (status == 'SCHEDULED' &&
                                  canScheduleMaintenance(role)) ||
                              (status == 'IN_PROGRESS' &&
                                  canCompleteMaintenance(role));
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                m['maintenanceNumber']?.toString() ??
                                    _labelEnum(m['maintenanceType']),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${_labelEnum(m['maintenanceType'])} · ${formatDate(m['scheduledDate'])}\nStatus: $status',
                                style: GoogleFonts.outfit(fontSize: 12),
                              ),
                              trailing: canAct
                                  ? TextButton(
                                      onPressed: () =>
                                          _onMaintenanceAction(m),
                                      child: Text(
                                        status == 'SCHEDULED'
                                            ? 'Start'
                                            : 'Complete',
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      Text(
                        'Compliance / inspections',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_complianceHistory.isEmpty)
                        Text(
                          'No compliance checks recorded.',
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        )
                      else
                        ..._complianceHistory.map((r) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  r['complianceNumber']?.toString() ??
                                      _labelEnum(r['complianceType']),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_labelEnum(r['complianceType'])} · ${formatDate(r['checkDate'])}\n${r['status'] ?? ''}',
                                  style: GoogleFonts.outfit(fontSize: 12),
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }

  String _labelEnum(dynamic v) {
    final s = v?.toString() ?? '';
    if (s.isEmpty) return '—';
    return s
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _row(String l, dynamic v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                l,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                v is String && v.contains('-') && v.length >= 8
                    ? formatDate(v)
                    : (v?.toString() ?? '—'),
                style: GoogleFonts.outfit(),
              ),
            ),
          ],
        ),
      );
}

// ——— Orders / Payments ———

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Map<String, dynamic>? _invoice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final i = await sl<PaymentService>().getInvoiceByOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _invoice = i;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _invoice = null;
        _loading = false;
      });
    }
  }

  bool get _isInternal {
    final role = context.read<AuthProvider>().user?.role;
    return role == UserRole.admin ||
        role == UserRole.manager ||
        role == UserRole.staff;
  }

  Future<void> _createInvoice() async {
    try {
      final created = await sl<PaymentService>().createInvoice(widget.orderId);
      if (!mounted) return;
      setState(() => _invoice = created);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _sendInvoice() async {
    if (_invoice == null) return;
    final id = _invoice!['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final emailCtrl = TextEditingController(
      text: _invoice!['customerEmail']?.toString() ??
          _invoice!['email']?.toString() ??
          '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        bool sending = false;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              Future<void> send() async {
                if (sending) return;
                setSheet(() => sending = true);
                try {
                  await sl<PaymentService>()
                      .sendInvoice(id, email: emailCtrl.text.trim());
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice sent')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                } finally {
                  if (ctx.mounted) setSheet(() => sending = false);
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send invoice',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Email (optional)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: sending ? null : send,
                          child: sending
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Invoice',
      showBack: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_invoice == null)
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No invoice found',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This order does not have an invoice yet.',
                        style: TextStyle(color: AppColors.mutedForeground),
                      ),
                      if (_isInternal) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _createInvoice,
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Create invoice'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      _invoice!['invoiceNumber']?.toString() ?? 'Invoice',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StatusBadge(
                      label: _invoice!['status']?.toString() ?? '',
                      status: _invoice!['status']?.toString(),
                    ),
                    const SizedBox(height: 16),
                    _row('Order', _invoice!['orderNumber']),
                    _row('Amount', formatCurrency(_invoice!['totalAmount'])),
                    _row('Due', formatDate(_invoice!['dueDate'])),
                    if (_isInternal) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _sendInvoice,
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Send invoice'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _row(String l, dynamic v) => ListTile(
        title: Text(l),
        trailing: Text(v?.toString() ?? '—'),
      );
}

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  Map<String, dynamic>? _stats;
  final _payments = <Map<String, dynamic>>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await sl<ReceiptService>().getStats();
      final role = context.read<AuthProvider>().user?.role;
      final isCustomer = role == UserRole.customer;

      PagedResponse<Map<String, dynamic>>? page;
      if (isCustomer) {
        final me = await sl<CustomerService>().getMe();
        final customerId = me['id']?.toString() ?? '';
        if (customerId.isNotEmpty) {
          page = await sl<PaymentService>().getByCustomer(customerId, size: 50);
        }
      } else {
        page = await sl<PaymentService>().getAll(size: 50);
      }

      setState(() {
        _stats = stats;
        _payments
          ..clear()
          ..addAll(page?.content ?? const <Map<String, dynamic>>[]);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Payment Receipts',
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_stats != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat('Total', _stats!['totalReceipts']),
                            _stat('Paid', _stats!['completedCount']),
                            _stat(
                                'Revenue', formatCurrency(_stats!['totalRevenue'])),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  ..._payments.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTileCard(
                        title: item['referenceNumber']?.toString() ?? 'Payment',
                        subtitle: formatCurrency(item['amount']),
                        status: item['status']?.toString(),
                        onTap: () =>
                            _showReceipt(context, item['id']?.toString() ?? ''),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _stat(String l, dynamic v) => Column(
        children: [
          Text('$v',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          Text(l, style: const TextStyle(color: AppColors.mutedForeground)),
        ],
      );

  Future<void> _showReceipt(BuildContext context, String paymentId) async {
    try {
      final r = await sl<ReceiptService>().getByPayment(paymentId);
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Receipt ${r['receiptNumber']}',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Order: ${r['orderNumber']}'),
              Text('Paid: ${formatCurrency(r['amountPaid'])}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await sl<ReceiptService>().sendReceipt(paymentId);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Email Receipt'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

// ——— Deliveries ———

class ProofOfDeliveryScreen extends StatefulWidget {
  const ProofOfDeliveryScreen({super.key, required this.deliveryId});
  final String deliveryId;

  @override
  State<ProofOfDeliveryScreen> createState() => _ProofOfDeliveryScreenState();
}

class _ProofOfDeliveryScreenState extends State<ProofOfDeliveryScreen> {
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  String? _imageBase64;
  bool _loading = false;

  @override
  void dispose() {
    _recipient.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _imageBase64 = base64Encode(bytes));
    }
  }

  Future<void> _complete() async {
    setState(() => _loading = true);
    try {
      await sl<DeliveryService>().updateStatus(widget.deliveryId, {
        'status': 'DELIVERED',
        'recipientName': _recipient.text.trim(),
        'recipientPhone': _phone.text.trim(),
        'driverNotes': _notes.text.trim(),
        if (_imageBase64 != null) 'proofOfDeliveryImage': _imageBase64,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery completed')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Proof of Delivery',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _recipient,
              decoration: const InputDecoration(labelText: 'Recipient Name')),
          TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Recipient Phone')),
          TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: Text(_imageBase64 != null ? 'Photo captured' : 'Take photo'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _complete,
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Complete Delivery'),
          ),
        ],
      ),
    );
  }
}

class DeliveryResponseScreen extends StatefulWidget {
  const DeliveryResponseScreen({
    super.key,
    required this.deliveryId,
    required this.accept,
  });

  final String deliveryId;
  final bool accept;

  @override
  State<DeliveryResponseScreen> createState() => _DeliveryResponseScreenState();
}

class _DeliveryResponseScreenState extends State<DeliveryResponseScreen> {
  final _reason = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (widget.accept) {
        await sl<DeliveryService>().acceptDelivery(widget.deliveryId);
      } else {
        await sl<DeliveryService>().rejectDelivery(
          widget.deliveryId,
          reason: _reason.text.trim(),
        );
      }
      if (mounted) context.go('/deliveries');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: widget.accept ? 'Accept Delivery' : 'Reject Delivery',
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!widget.accept)
              TextField(
                controller: _reason,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor:
                    widget.accept ? AppColors.success : AppColors.destructive,
              ),
              child: Text(widget.accept ? 'Accept' : 'Reject'),
            ),
          ],
        ),
      ),
    );
  }
}

// ——— Customers / Settings extras ———

class CustomerSegmentsScreen extends StatefulWidget {
  const CustomerSegmentsScreen({super.key});

  @override
  State<CustomerSegmentsScreen> createState() => _CustomerSegmentsScreenState();
}

class _CustomerSegmentsScreenState extends State<CustomerSegmentsScreen> {
  List<Map<String, dynamic>> _segments = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final segs = await sl<SegmentService>().getSegments();
      final stats = await sl<SegmentService>().getStats();
      setState(() {
        _segments = segs;
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Customer Segments',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_stats != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '${_stats!['segmentCount']} segments · '
                          '${_stats!['totalCustomers']} customers',
                        ),
                      ),
                    ),
                  ..._segments.map(
                    (s) => ListTileCard(
                      title: s['name']?.toString() ?? 'Segment',
                      subtitle: s['description']?.toString(),
                      onTap: () => _showCustomers(s['id']?.toString() ?? ''),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showCustomers(String segmentId) async {
    final page = await sl<SegmentService>().getSegmentCustomers(segmentId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scroll) => ListView.builder(
          controller: scroll,
          itemCount: page.content.length,
          itemBuilder: (_, i) {
            final c = page.content[i];
            return ListTile(
              title: Text(c['name']?.toString() ?? ''),
              subtitle: Text(c['phoneNumber']?.toString() ?? ''),
            );
          },
        ),
      ),
    );
  }
}

class NotificationTemplatesScreen extends StatelessWidget {
  const NotificationTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      title: 'Notification Templates',
      searchable: false,
      loadPage: (_, __) => sl<TemplateService>().getTemplates(),
      itemBuilder: (item) => ListTileCard(
        title: item['name']?.toString() ?? 'Template',
        subtitle: item['type']?.toString(),
        badge: item['isActive'] == true ? 'Active' : 'Inactive',
      ),
    );
  }
}

class PermissionGroupsScreen extends StatelessWidget {
  const PermissionGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      title: 'Permission Groups',
      searchable: false,
      loadPage: (_, __) => sl<PermissionService>().getGroups(),
      itemBuilder: (item) => ListTileCard(
        title: item['name']?.toString() ?? 'Group',
        subtitle: item['description']?.toString(),
      ),
    );
  }
}

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _tin = TextEditingController();
  final _website = TextEditingController();
  LocationValues _loc = const LocationValues();

  bool _loading = true;
  bool _saving = false;

  bool get _canEdit => context.read<AuthProvider>().user?.role == UserRole.admin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _tin.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await sl<SettingsService>().getCompanySettings();
      if (!mounted) return;
      _name.text = c['name']?.toString() ?? '';
      _email.text = c['email']?.toString() ?? '';
      _phone.text = c['phone']?.toString() ?? '';
      _address.text = c['address']?.toString() ?? '';
      _tin.text = c['tin']?.toString() ?? '';
      _website.text = c['website']?.toString() ?? '';
      _loc = LocationValues(
        province: c['province']?.toString(),
        district: c['district']?.toString(),
        sector: c['sector']?.toString(),
        cell: c['cell']?.toString(),
        village: c['village']?.toString(),
      );
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_canEdit || _saving) return;
    setState(() => _saving = true);
    try {
      await sl<SettingsService>().updateCompanySettings({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'tin': _tin.text.trim(),
        if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
        'province': _loc.province,
        'district': _loc.district,
        'sector': _loc.sector,
        'cell': _loc.cell,
        'village': _loc.village,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company settings updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Company Settings',
      showBack: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _name,
                  enabled: _canEdit,
                  decoration: const InputDecoration(labelText: 'Company name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tin,
                  enabled: _canEdit,
                  decoration: const InputDecoration(labelText: 'TIN'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  enabled: _canEdit,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  enabled: _canEdit,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  enabled: _canEdit,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _website,
                  enabled: _canEdit,
                  decoration:
                      const InputDecoration(labelText: 'Website (optional)'),
                ),
                const SizedBox(height: 12),
                LocationSelector(
                  values: _loc,
                  enabled: _canEdit,
                  onChanged: (v) => setState(() => _loc = v),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: (!_canEdit || _saving) ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_canEdit ? 'Save' : 'View only'),
                ),
              ],
            ),
    );
  }
}

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  List<Map<String, dynamic>> _prefs = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await sl<SettingsService>().getNotificationPreferences();
      if (!mounted) return;
      setState(() {
        _prefs = p;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAll() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await sl<SettingsService>().updateAllNotificationPreferences(_prefs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Notification Preferences',
      showBack: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._prefs.asMap().entries.map((e) {
                  final idx = e.key;
                  final pref = e.value;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pref['label']?.toString() ??
                                pref['type']?.toString() ??
                                'Preference',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if ((pref['description']?.toString().isNotEmpty ??
                              false))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                pref['description']?.toString() ?? '',
                                style: const TextStyle(
                                    color: AppColors.mutedForeground),
                              ),
                            ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Email'),
                            value: pref['emailEnabled'] == true,
                            onChanged: (v) => setState(() {
                              _prefs[idx] = {
                                ...pref,
                                'emailEnabled': v,
                              };
                            }),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Push'),
                            value: pref['pushEnabled'] == true,
                            onChanged: (v) => setState(() {
                              _prefs[idx] = {
                                ...pref,
                                'pushEnabled': v,
                              };
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _saveAll,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save preferences'),
                ),
              ],
            ),
    );
  }
}

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String _theme = 'system';
  String _language = 'en';
  String _timezone = 'Africa/Kigali';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await sl<SettingsService>().getAppearanceSettings();
      if (!mounted) return;
      setState(() {
        _theme = s['theme']?.toString() ?? 'system';
        _language = s['language']?.toString() ?? 'en';
        _timezone = s['timezone']?.toString() ?? 'Africa/Kigali';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await sl<SettingsService>().updateAppearanceSettings({
        'theme': _theme,
        'language': _language,
        'timezone': _timezone,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appearance updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Appearance',
      showBack: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  value: _theme,
                  decoration: const InputDecoration(labelText: 'Theme'),
                  items: const [
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    DropdownMenuItem(value: 'system', child: Text('System')),
                  ],
                  onChanged: (v) => setState(() => _theme = v ?? 'system'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'fr', child: Text('French')),
                    DropdownMenuItem(value: 'rw', child: Text('Kinyarwanda')),
                  ],
                  onChanged: (v) => setState(() => _language = v ?? 'en'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _timezone,
                  decoration: const InputDecoration(labelText: 'Timezone'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Africa/Kigali', child: Text('Africa/Kigali')),
                    DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                  ],
                  onChanged: (v) =>
                      setState(() => _timezone = v ?? 'Africa/Kigali'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
    );
  }
}

class ReportBuilderScreen extends StatefulWidget {
  const ReportBuilderScreen({super.key});

  @override
  State<ReportBuilderScreen> createState() => _ReportBuilderScreenState();
}

class _ReportBuilderScreenState extends State<ReportBuilderScreen> {
  List<Map<String, dynamic>> _fields = [];
  List<Map<String, dynamic>> _saved = [];
  List<dynamic> _preview = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fields = await sl<CustomReportService>().getFields();
      final saved = await sl<CustomReportService>().getSavedReports();
      setState(() {
        _fields = fields;
        _saved = saved;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _runPreview() async {
    if (_fields.isEmpty) return;
    final selected = _fields.take(5).map((f) => f['key']).toList();
    final data = await sl<CustomReportService>().preview({
      'fields': selected,
      'limit': 20,
    });
    setState(() => _preview = data);
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Report Builder',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${_fields.length} fields available',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                FilledButton(
                  onPressed: _runPreview,
                  child: const Text('Preview Report'),
                ),
                if (_preview.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Preview (${_preview.length} rows)'),
                  ..._preview.take(10).map(
                        (row) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(row.toString()),
                          ),
                        ),
                      ),
                ],
                const SizedBox(height: 24),
                Text('Saved reports (${_saved.length})',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                ..._saved.map(
                  (r) => ListTileCard(
                    title: r['name']?.toString() ?? 'Report',
                    subtitle: r['description']?.toString(),
                  ),
                ),
              ],
            ),
    );
  }
}

class EnhancedMaintenanceScreen extends StatefulWidget {
  const EnhancedMaintenanceScreen({super.key});

  @override
  State<EnhancedMaintenanceScreen> createState() =>
      _EnhancedMaintenanceScreenState();
}

class _EnhancedMaintenanceScreenState extends State<EnhancedMaintenanceScreen> {
  final _inv = sl<InventoryService>();
  final _maint = sl<MaintenanceService>();
  final _search = TextEditingController();
  final _scroll = ScrollController();

  /// `all` | `maintenance` (UNDER_MAINTENANCE + MAINTENANCE) | `inspection` |
  /// `expired` | `RETIRED`
  String _listFilter = 'all';

  bool _dashLoading = true;
  bool _listLoading = true;
  bool _loadingMore = false;
  String? _listError;

  int _totalCylinders = 0;
  int _inMaintenanceTotal = 0;
  int _scheduledToday = 0;
  List<Map<String, dynamic>> _needingInspection = [];
  List<Map<String, dynamic>> _recentMaintenance = [];
  Map<String, dynamic>? _analytics;

  List<Map<String, dynamic>> _listItems = [];
  int _page = 0;
  static const _pageSize = 20;
  bool _hasMore = true;

  /// True when the list reflects `/cylinders/search` results (filter chips ignored).
  bool _searchActive = false;

  static const _filterChips = <(String key, String label)>[
    ('all', 'All'),
    ('maintenance', 'Maintenance'),
    ('inspection', 'Due inspection'),
    ('expired', 'Expired'),
    ('RETIRED', 'Retired'),
  ];

  bool get _paginatedFilter =>
      !_searchActive && (_listFilter == 'all' || _listFilter == 'RETIRED');

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_paginatedFilter || !_hasMore || _listLoading || _loadingMore) {
      return;
    }
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 240) {
      _loadList(reset: false);
    }
  }

  bool _canViewAnalytics(UserRole? role) =>
      role == UserRole.admin || role == UserRole.manager;

  String _cylinderSubtitle(Map<String, dynamic> c) {
    final parts = <String>[];
    final product = c['productName']?.toString();
    if (product != null && product.isNotEmpty) parts.add(product);
    final wh = c['warehouseName']?.toString();
    if (wh != null && wh.isNotEmpty) parts.add(wh);
    final next = c['nextInspectionDate'];
    if (next != null) {
      parts.add('Next inspection ${formatDate(next)}');
    }
    return parts.isEmpty ? 'Cylinder' : parts.join(' · ');
  }

  Future<void> _refresh() async {
    await Future.wait([_loadDashboard(), _loadList()]);
  }

  Future<void> _loadDashboard() async {
    setState(() => _dashLoading = true);
    try {
      final user = context.read<AuthProvider>().user;
      final pageFuture = _inv.getCylinders(page: 0, size: 1);
      final underFuture = _inv.getCylinderCountByStatus('UNDER_MAINTENANCE');
      final maintFuture = _inv.getCylinderCountByStatus('MAINTENANCE');
      final inspectFuture = _inv.getCylindersNeedingInspection();
      final recentFuture = _maint.getAllMaintenance(page: 0, size: 5);
      final todayFuture = _maint.getScheduledForToday();
      final analyticsFuture = _canViewAnalytics(user?.role)
          ? _inv.getCylinderAnalytics().catchError((_) => <String, dynamic>{})
          : Future<Map<String, dynamic>>.value({});

      final page = await pageFuture;
      final under = await underFuture;
      final maint = await maintFuture;
      final inspect = await inspectFuture;
      final recent = await recentFuture;
      final today = await todayFuture;
      final analytics = await analyticsFuture;

      if (!mounted) return;
      setState(() {
        _totalCylinders = page.totalElements;
        _inMaintenanceTotal = under + maint;
        _needingInspection = inspect;
        _recentMaintenance = recent.content;
        _scheduledToday = today.length;
        _analytics = analytics.isEmpty ? null : analytics;
        _dashLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _dashLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load maintenance summary: $e')),
      );
    }
  }

  Future<void> _loadList({bool reset = true}) async {
    if (reset) {
      setState(() {
        _listLoading = true;
        _listError = null;
        _page = 0;
        _hasMore = true;
      });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final q = _search.text.trim();
      if (q.isNotEmpty) {
        final page = reset ? 0 : _page;
        final r = await _inv.searchCylinders(q, page: page, size: _pageSize);
        if (!mounted) return;
        setState(() {
          if (reset) {
            _listItems = r.content;
          } else {
            _listItems = [..._listItems, ...r.content];
          }
          _page = page + 1;
          _hasMore = r.hasMore;
          _listLoading = false;
          _loadingMore = false;
          _searchActive = true;
        });
        return;
      }

      List<Map<String, dynamic>> rows;
      var hasMore = false;

      switch (_listFilter) {
        case 'all':
          final page = reset ? 0 : _page;
          final r = await _inv.getCylinders(
            page: page,
            size: _pageSize,
            sortBy: 'updatedAt',
            sortDir: 'desc',
          );
          rows = r.content;
          hasMore = r.hasMore;
          if (!reset) {
            if (!mounted) return;
            setState(() {
              _listItems = [..._listItems, ...rows];
              _page = page + 1;
              _hasMore = hasMore;
              _listLoading = false;
              _loadingMore = false;
              _searchActive = false;
            });
            return;
          }
          break;
        case 'maintenance':
          final byId = <String, Map<String, dynamic>>{};
          for (final c
              in (await _inv.getCylindersByStatus(
                'UNDER_MAINTENANCE',
                page: 0,
                size: 50,
              ))
                  .content) {
            byId[c['id']?.toString() ?? ''] = c;
          }
          for (final c in (await _inv.getCylindersByStatus(
            'MAINTENANCE',
            page: 0,
            size: 50,
          ))
              .content) {
            byId[c['id']?.toString() ?? ''] = c;
          }
          rows = byId.values.toList();
          hasMore = false;
          break;
        case 'inspection':
          rows = await _inv.getCylindersNeedingInspection();
          hasMore = false;
          break;
        case 'expired':
          rows = await _inv.getExpiredCylinders();
          hasMore = false;
          break;
        case 'RETIRED':
          final page = reset ? 0 : _page;
          final r = await _inv.getCylindersByStatus(
            'RETIRED',
            page: page,
            size: _pageSize,
          );
          rows = r.content;
          hasMore = r.hasMore;
          if (!reset) {
            if (!mounted) return;
            setState(() {
              _listItems = [..._listItems, ...rows];
              _page = page + 1;
              _hasMore = hasMore;
              _listLoading = false;
              _loadingMore = false;
              _searchActive = false;
            });
            return;
          }
          break;
        default:
          rows = [];
      }
      if (!mounted) return;
      setState(() {
        _listItems = rows;
        _page = 1;
        _hasMore = hasMore;
        _listLoading = false;
        _loadingMore = false;
        _searchActive = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listLoading = false;
        _loadingMore = false;
        _listError = e.toString();
        if (reset) _listItems = [];
        _searchActive = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    if (_listItems.isEmpty) return;
    final sb = StringBuffer()
      ..writeln(
        'Serial,Product,Warehouse,Status,Last Inspection,Next Inspection,Refills',
      );
    for (final item in _listItems) {
      sb.writeln([
        _csvCell(item['serialNumber']),
        _csvCell(item['productName']),
        _csvCell(item['warehouseName']),
        _csvCell(item['status']),
        _csvCell(item['lastInspectionDate']),
        _csvCell(item['nextInspectionDate']),
        _csvCell(item['refillCount']),
      ].join(','));
    }
    try {
      await FileShare.shareBytes(
        SharedFile(
          filename:
              'cylinders_${DateTime.now().millisecondsSinceEpoch}.csv',
          bytes: Uint8List.fromList(utf8.encode(sb.toString())),
          mimeType: 'text/csv',
        ),
        text: 'Cylinder export (${_listItems.length} rows)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  String _csvCell(dynamic v) {
    final s = v?.toString() ?? '';
    if (s.contains(',') || s.contains('"')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  void _setFilter(String key) {
    if (_listFilter == key) return;
    _search.clear();
    setState(() => _listFilter = key);
    _loadList();
  }

  Future<void> _openSchedule() async {
    final ok = await showScheduleMaintenanceSheet(context);
    if (ok == true) _refresh();
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final certified = (_totalCylinders - _needingInspection.length)
        .clamp(0, _totalCylinders);
    final upcoming = _needingInspection.take(4).toList();
    final ageList = (_analytics?['ageDistribution'] as List?) ?? const [];
    final maint = _analytics?['maintenanceAlerts'] as Map<String, dynamic>?;
    final alerts = (maint?['alertList'] as List?) ?? const [];

    return MobileShell(
      title: 'Cylinder maintenance',
      actions: [
        IconButton(
          tooltip: 'Export list',
          onPressed: _listItems.isEmpty ? null : _exportCsv,
          icon: const Icon(Icons.download_outlined),
        ),
        if (canScheduleMaintenance(role))
          IconButton(
            tooltip: 'Schedule maintenance',
            onPressed: _openSchedule,
            icon: const Icon(Icons.add),
          ),
      ],
      floatingActionButton: canScheduleMaintenance(role)
          ? FloatingActionButton.extended(
              onPressed: _openSchedule,
              icon: const Icon(Icons.build),
              label: const Text('Schedule'),
            )
          : null,
      child: Column(
        children: [
          if (_dashLoading || (_listLoading && _listItems.isEmpty))
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Track inspections, expiry, and maintenance workload.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statTile(
                                label: 'Total',
                                value: '$_totalCylinders',
                                icon: Icons.propane_tank_outlined,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              _statTile(
                                label: 'In maintenance',
                                value: '$_inMaintenanceTotal',
                                icon: Icons.build_circle_outlined,
                                color: Colors.amber.shade800,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _statTile(
                                label: 'Due inspection',
                                value: '${_needingInspection.length}',
                                icon: Icons.warning_amber_outlined,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              _statTile(
                                label: 'Certified (approx.)',
                                value: '$certified',
                                icon: Icons.verified_outlined,
                                color: Colors.green.shade700,
                              ),
                            ],
                          ),
                          if (_scheduledToday > 0) ...[
                            const SizedBox(height: 8),
                            Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.today_outlined,
                                  color: AppColors.primary,
                                ),
                                title: Text(
                                  '$_scheduledToday scheduled today',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Work orders from maintenance module',
                                  style: GoogleFonts.outfit(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            'Upcoming inspections',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (upcoming.isEmpty)
                            Text(
                              'No cylinders are due for inspection right now.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            )
                          else
                            SizedBox(
                              height: 118,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: upcoming.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (_, i) {
                                  final c = upcoming[i];
                                  return SizedBox(
                                    width: 200,
                                    child: Card(
                                      child: InkWell(
                                        onTap: () => context.push(
                                          '/inventory/cylinders/${c['id']}',
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c['serialNumber']
                                                        ?.toString() ??
                                                    '—',
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w600,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                c['productName']
                                                        ?.toString() ??
                                                    '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              const Spacer(),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.event_outlined,
                                                    size: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      formatDate(
                                                        c['nextInspectionDate'],
                                                      ),
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (_recentMaintenance.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Recent maintenance',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._recentMaintenance.map((m) {
                              final cylId = m['cylinderId']?.toString();
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  dense: true,
                                  title: Text(
                                    m['cylinderSerialNumber']?.toString() ??
                                        m['maintenanceNumber']?.toString() ??
                                        'Maintenance',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${m['maintenanceType']} · ${m['status']} · ${formatDate(m['scheduledDate'])}',
                                    style: GoogleFonts.outfit(fontSize: 12),
                                  ),
                                  onTap: cylId != null
                                      ? () => context.push(
                                            '/inventory/cylinders/$cylId',
                                          )
                                      : null,
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _search,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search by serial or barcode…',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                tooltip: 'Search',
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: _loadList,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _loadList(),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final e in _filterChips)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(e.$2),
                                      selected:
                                          !_searchActive && _listFilter == e.$1,
                                      onSelected: (_) {
                                        _setFilter(e.$1);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_analytics != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Analytics',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (alerts.isNotEmpty) ...[
                              Text(
                                'Alerts',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...alerts.take(5).map((raw) {
                                final a = raw as Map<String, dynamic>;
                                final sev =
                                    (a['severity'] ?? '').toString().toUpperCase();
                                final color = sev == 'HIGH' || sev == 'CRITICAL'
                                    ? Colors.red.shade700
                                    : sev == 'MEDIUM'
                                        ? Colors.orange.shade800
                                        : Colors.blueGrey;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                      a['message']?.toString() ??
                                          a['alertType']?.toString() ??
                                          'Alert',
                                      style: GoogleFonts.outfit(fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      a['serialNumber']?.toString() ?? '',
                                      style: GoogleFonts.outfit(fontSize: 12),
                                    ),
                                    trailing: Icon(Icons.circle, size: 10, color: color),
                                  ),
                                );
                              }),
                            ],
                            if (ageList.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Age distribution',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...ageList.map((raw) {
                                final row = raw as Map<String, dynamic>;
                                final label =
                                    row['ageRange']?.toString() ?? '—';
                                final count = (row['count'] as num?)?.toInt() ?? 0;
                                final pct =
                                    (row['percentage'] as num?)?.toDouble() ?? 0.0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(label,
                                              style: GoogleFonts.outfit(
                                                  fontSize: 12)),
                                          Text('$count',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              )),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: (pct / 100).clamp(0.0, 1.0),
                                          minHeight: 6,
                                          backgroundColor:
                                              Colors.grey.shade200,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'Cylinders',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  if (_listError != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _listError!,
                          style: GoogleFonts.outfit(
                            color: Colors.red.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (!_listLoading && _listItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No cylinders in this view.',
                          style: GoogleFonts.outfit(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            if (_listLoading && _listItems.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            if (i >= _listItems.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: _loadingMore
                                      ? const CircularProgressIndicator()
                                      : Text(
                                          _hasMore && _paginatedFilter
                                              ? 'Scroll for more…'
                                              : '',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                ),
                              );
                            }
                            final item = _listItems[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ListTileCard(
                                title: item['serialNumber']?.toString() ??
                                    'Cylinder',
                                subtitle: _cylinderSubtitle(item),
                                status: item['status']?.toString(),
                                onTap: () => context.push(
                                  '/inventory/cylinders/${item['id']}',
                                ),
                              ),
                            );
                          },
                          childCount: (_listLoading && _listItems.isEmpty)
                              ? 1
                              : _listItems.length +
                                  (_paginatedFilter && (_hasMore || _loadingMore)
                                      ? 1
                                      : 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
