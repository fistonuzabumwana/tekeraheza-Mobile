import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'dart:async';

import '../../core/di/service_locator.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/maps_launch.dart';
import '../../core/widgets/data_list_screen.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/list_tile_card.dart';
import '../../core/widgets/mobile_shell.dart';
import '../../core/widgets/pick_cylinders_sheet.dart';
import '../../core/qr/cylinder_qr.dart';
import '../../core/utils/file_share.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/alert_service.dart';
import '../../services/communication_service.dart';
import '../../services/credit_service.dart';
import '../../services/customer_service.dart';
import '../../services/delivery_service.dart';
import '../../services/inventory_service.dart';
import '../../services/loyalty_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/report_service.dart';
import '../../services/session_service.dart';
import '../../services/settings_service.dart';
import '../../services/system_service.dart';
import '../../services/user_service.dart';

// ——— Orders ———

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final isCustomer = role == UserRole.customer;

    return DataListScreen(
      title: 'Orders',
      fab: FloatingActionButton(
        onPressed: () => context.push('/orders/new'),
        child: const Icon(Icons.add),
      ),
      loadPage: (page, query) async {
        if (query != null && query.isNotEmpty) {
          final r = await sl<OrderService>().search(query, page: page);
          return r.content;
        }
        if (isCustomer) {
          final me = await sl<CustomerService>().getMe();
          final customerId = me['id']?.toString() ?? '';
          if (customerId.isEmpty) return <Map<String, dynamic>>[];
          final r = await sl<OrderService>().getByCustomer(
            customerId,
            page: page,
          );
          return r.content;
        }
        final r = await sl<OrderService>().getAll(page: page);
        return r.content;
      },
      itemBuilder: (item) => ListTileCard(
        title: item['orderNumber']?.toString() ?? 'Order',
        subtitle:
            '${item['customerName'] ?? ''} • ${formatCurrency(item['totalAmount'])}',
        status: item['status']?.toString(),
        onTap: () => context.push('/orders/${item['id']}'),
      ),
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await sl<OrderService>().getById(widget.orderId);
      setState(() {
        _order = o;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    await sl<OrderService>().confirm(widget.orderId);
    _load();
  }

  Future<void> _cancel() async {
    await sl<OrderService>().cancel(widget.orderId);
    if (mounted) context.pop();
  }

  Future<void> _recordPayment() async {
    if (_order == null) return;

    final amountCtrl = TextEditingController(
      text: ((_order!['totalAmount'] ?? 0) - (_order!['paidAmount'] ?? 0))
          .toString(),
    );
    final txIdCtrl = TextEditingController(text: _order!['transactionId']?.toString() ?? '');
    final txRefCtrl = TextEditingController();
    final momoCtrl = TextEditingController(text: _order!['mobileMoneyNumber']?.toString() ?? '');
    final bankNameCtrl = TextEditingController(text: _order!['bankName']?.toString() ?? '');
    final bankAccCtrl = TextEditingController(text: _order!['bankAccount']?.toString() ?? '');

    String method = (_order!['paymentMethod']?.toString().isNotEmpty ?? false)
        ? _order!['paymentMethod'].toString()
        : 'CASH';
    String confirmation = (_order!['paymentConfirmation']?.toString().isNotEmpty ?? false)
        ? _order!['paymentConfirmation'].toString()
        : 'SUCCESS';
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              Future<void> save() async {
                if (saving) return;
                setSheet(() => saving = true);
                try {
                  await sl<PaymentService>().create({
                    'orderId': widget.orderId,
                    'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
                    'paymentMethod': method,
                    if (txRefCtrl.text.trim().isNotEmpty)
                      'transactionReference': txRefCtrl.text.trim(),
                    if (txIdCtrl.text.trim().isNotEmpty)
                      'transactionId': txIdCtrl.text.trim(),
                    'paymentConfirmation': confirmation,
                    if (method == 'MOBILE_MONEY' && momoCtrl.text.trim().isNotEmpty)
                      'mobileMoneyNumber': momoCtrl.text.trim(),
                    if (method == 'BANK_TRANSFER') ...{
                      if (bankNameCtrl.text.trim().isNotEmpty) 'bankName': bankNameCtrl.text.trim(),
                      if (bankAccCtrl.text.trim().isNotEmpty) 'bankAccount': bankAccCtrl.text.trim(),
                    },
                  });
                  if (context.mounted) Navigator.of(ctx).pop();
                  await _load();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                } finally {
                  if (ctx.mounted) setSheet(() => saving = false);
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Record Payment',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Amount (RWF)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: method,
                      decoration:
                          const InputDecoration(labelText: 'Payment method'),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('CASH')),
                        DropdownMenuItem(
                            value: 'MOBILE_MONEY', child: Text('MOBILE_MONEY')),
                        DropdownMenuItem(
                            value: 'BANK_TRANSFER', child: Text('BANK_TRANSFER')),
                        DropdownMenuItem(value: 'CARD', child: Text('CARD')),
                      ],
                      onChanged: (v) => setSheet(() => method = v ?? 'CASH'),
                    ),
                    if (method == 'MOBILE_MONEY') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: momoCtrl,
                        decoration:
                            const InputDecoration(labelText: 'MoMo Number'),
                      ),
                    ],
                    if (method == 'BANK_TRANSFER') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: bankNameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Bank name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bankAccCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Bank account'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: txIdCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Transaction ID'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: txRefCtrl,
                      decoration: const InputDecoration(
                          labelText: 'External reference (optional)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: confirmation,
                      decoration: const InputDecoration(
                          labelText: 'Confirmation status'),
                      items: const [
                        DropdownMenuItem(
                            value: 'SUCCESS', child: Text('SUCCESS')),
                        DropdownMenuItem(
                            value: 'PENDING', child: Text('PENDING')),
                        DropdownMenuItem(value: 'FAILED', child: Text('FAILED')),
                      ],
                      onChanged: (v) =>
                          setSheet(() => confirmation = v ?? 'SUCCESS'),
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
                            onPressed: saving ? null : save,
                            child: saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Record'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    amountCtrl.dispose();
    txIdCtrl.dispose();
    txRefCtrl.dispose();
    momoCtrl.dispose();
    bankNameCtrl.dispose();
    bankAccCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _order?['status']?.toString() ?? '';
    final role = context.watch<AuthProvider>().user?.role;
    final isInternal = role == UserRole.admin ||
        role == UserRole.manager ||
        role == UserRole.staff;

    return MobileShell(
      title: 'Order Details',
      showBack: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _order!['orderNumber']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        StatusBadge(label: status, status: status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailRow('Customer', _order!['customerName']),
                    _DetailRow('Total', formatCurrency(_order!['totalAmount'])),
                    _DetailRow('Paid', formatCurrency(_order!['paidAmount'])),
                    _DetailRow('Payment', _order!['paymentMethod']),
                    _DetailRow('Created', formatDate(_order!['createdAt'])),
                    if (_order!['deliveryAddress'] != null)
                      _DetailRow('Address', _order!['deliveryAddress']),
                    const SizedBox(height: 24),
                    if (status == 'PENDING' && isInternal)
                      FilledButton(
                        onPressed: _confirm,
                        child: const Text('Confirm Order'),
                      ),
                    if (isInternal &&
                        (_order!['paymentStatus']?.toString() != 'COMPLETED'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: _recordPayment,
                          icon: const Icon(Icons.credit_card),
                          label: const Text('Record Payment'),
                        ),
                      ),
                    if (status != 'CANCELLED' && status != 'DELIVERED') ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _cancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.destructive,
                        ),
                        child: const Text('Cancel Order'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        try {
                          final d = await sl<DeliveryService>()
                              .getByOrderId(widget.orderId);
                          if (!mounted) return;
                          context.push('/deliveries/${d['id']}/track');
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No delivery found for this order yet.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('View Delivery'),
                    ),
                  ],
                ),
    );
  }
}

// ——— Inventory ———

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Inventory',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickAction(
                    context,
                    icon: Icons.warning_amber_rounded,
                    label: 'Low stock',
                    onTap: () => context.push('/inventory/low-stock'),
                  ),
                  _quickAction(
                    context,
                    icon: Icons.swap_horiz,
                    label: 'Returns',
                    onTap: () => context.push('/inventory/returns'),
                  ),
                  _quickAction(
                    context,
                    icon: Icons.tune,
                    label: 'Adjust stock',
                    onTap: () => context.push('/inventory/stock-adjustment'),
                  ),
                  _quickAction(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'Scan',
                    onTap: () => context.push('/inventory/scanner'),
                  ),
                  _quickAction(
                    context,
                    icon: Icons.warehouse_outlined,
                    label: 'Warehouses',
                    onTap: () => context.push('/inventory/warehouses'),
                  ),
                  _quickAction(
                    context,
                    icon: Icons.local_shipping_outlined,
                    label: 'Suppliers',
                    onTap: () => context.push('/inventory/suppliers'),
                  ),
                  _quickAction(
                    context,
                    icon: Icons.add_circle_outline,
                    label: 'Add product',
                    onTap: () => context.push('/inventory/add-product'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const TabBar(
              tabs: [
                Tab(text: 'Products'),
                Tab(text: 'Cylinders'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: const [
                  _ProductsTab(),
                  _CylindersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      title: '',
      loadPage: (page, query) async {
        if (query != null && query.isNotEmpty) {
          final r =
              await sl<InventoryService>().searchProducts(query.toString());
          return r.content;
        }
        final r = await sl<InventoryService>().getProducts(page: page);
        return r.content;
      },
      itemBuilder: (item) => ListTileCard(
        title: item['name']?.toString() ?? 'Product',
        subtitle:
            '${item['cylinderSize'] ?? ''} • ${item['unitPrice'] ?? 0} RWF',
        badge: (item['isLowStock'] == true) ? 'LOW' : null,
        onTap: () => context.push('/inventory/products/${item['id']}'),
      ),
    );
  }
}

class _CylindersTab extends StatelessWidget {
  const _CylindersTab();

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      title: '',
      searchable: false,
      loadPage: (page, _) async {
        final r = await sl<InventoryService>().getCylinders(page: page);
        return r.content;
      },
      itemBuilder: (item) => ListTileCard(
        title: item['serialNumber']?.toString() ?? 'Cylinder',
        subtitle: item['productName']?.toString() ??
            item['product']?['name']?.toString(),
        badge: item['status']?.toString(),
        onTap: () => context.push('/inventory/cylinders/${item['id']}'),
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _product;

  @override
  void initState() {
    super.initState();
    sl<InventoryService>().getProductById(widget.productId).then((p) {
      if (mounted) setState(() => _product = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Product',
      child: _product == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DetailRow('Name', _product!['name']),
                _DetailRow('SKU', _product!['sku']),
                _DetailRow('Size', _product!['cylinderSize']),
                _DetailRow('Price', _product!['unitPrice']?.toString()),
                _DetailRow('Stock', _product!['totalStock']?.toString()),
              ],
            ),
    );
  }
}

class LowStockScreen extends StatelessWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      title: 'Low Stock Alerts',
      loadPage: (_, __) => sl<InventoryService>().getLowStock(),
      searchable: false,
      itemBuilder: (item) => ListTileCard(
        title: item['productName']?.toString() ?? 'Product',
        subtitle: 'Qty: ${item['quantity'] ?? 0}',
        badge: 'LOW',
      ),
    );
  }
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _serial = TextEditingController();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  Map<String, dynamic>? _result;
  String? _lookupMessage;
  bool _scanning = true;
  bool _loading = false;

  @override
  void dispose() {
    _serial.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _lookup(String raw) async {
    final code = normalizeScanInput(raw);
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _lookupMessage = null;
    });
    try {
      final response = await sl<InventoryService>().lookupCylinder(code);
      final cylinder = response['cylinder'] as Map<String, dynamic>?;
      setState(() {
        _result = cylinder;
        _lookupMessage = response['message']?.toString();
        _serial.text = cylinder?['serialNumber']?.toString() ?? code;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      setState(() => _result = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_scanning || _loading) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;
    setState(() => _scanning = false);
    _lookup(raw);
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'QR / Serial Scanner',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 260,
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _scanning ? 'Point camera at cylinder QR label' : 'Scan paused — tap Resume to scan again',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _serial,
                  decoration: const InputDecoration(
                    labelText: 'Serial or QR payload',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : () => _lookup(_serial.text),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lookup'),
              ),
            ],
          ),
          if (!_scanning)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: () => setState(() => _scanning = true),
                child: const Text('Resume camera scan'),
              ),
            ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lookupMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _lookupMessage!,
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                    Text('Serial: ${_result!['serialNumber']}'),
                    Text('Status: ${_result!['status']}'),
                    Text('Product: ${_result!['productName']}'),
                    if (_result!['productCylinderSize'] != null)
                      Text('Size: ${_result!['productCylinderSize']}'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ——— Deliveries ———

class DeliveriesListScreen extends StatelessWidget {
  const DeliveriesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final isCustomer = role == UserRole.customer;
    final isDriver = role == UserRole.deliveryPersonnel;

    return DataListScreen(
      title: 'Deliveries',
      loadPage: (page, _) async {
        if (isCustomer) {
          final me = await sl<CustomerService>().getMe();
          final customerId = me['id']?.toString() ?? '';
          if (customerId.isEmpty) return <Map<String, dynamic>>[];
          final r = await sl<DeliveryService>().getByCustomer(
            customerId,
            page: page,
          );
          return r.content;
        }
        if (isDriver) {
          return sl<DeliveryService>().getMyDeliveries();
        }
        final r = await sl<DeliveryService>().getAll(page: page);
        return r.content;
      },
      searchable: false,
      itemBuilder: (item) => ListTileCard(
        title: item['orderNumber']?.toString() ?? 'Delivery',
        subtitle: item['customerName']?.toString(),
        badge: item['status']?.toString(),
        onTap: () => context.push('/deliveries/${item['id']}/track'),
      ),
    );
  }
}

class DeliveryTrackScreen extends StatefulWidget {
  const DeliveryTrackScreen({super.key, required this.deliveryId});
  final String deliveryId;

  @override
  State<DeliveryTrackScreen> createState() => _DeliveryTrackScreenState();
}

class _DeliveryTrackScreenState extends State<DeliveryTrackScreen> {
  Map<String, dynamic>? _delivery;
  bool _pushing = false;
  bool _live = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    sl<DeliveryService>().getById(widget.deliveryId).then((d) {
      if (mounted) setState(() => _delivery = d);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartPusher());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _maybeStartPusher() {
    final role = context.read<AuthProvider>().user?.role;
    if (role != UserRole.deliveryPersonnel) return;
    _startPusher();
  }

  Future<void> _startPusher() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _pushOnce());
    await _pushOnce();
  }

  Future<void> _pushOnce() async {
    if (!_live) return;
    if (_delivery == null) return;

    final role = context.read<AuthProvider>().user?.role;
    if (role != UserRole.deliveryPersonnel) return;

    // Only push on active states
    final status = _delivery?['status']?.toString();
    const active = {
      'ASSIGNED',
      'PICKED_UP',
      'IN_TRANSIT',
      'ARRIVED',
      'OUT_FOR_DELIVERY',
    };
    if (status == null || !active.contains(status)) return;

    if (_pushing) return;
    setState(() => _pushing = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await sl<DeliveryService>().updateLocation(widget.deliveryId, {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
      await _reload();
    } catch (_) {
      // ignore; user can still refresh manually
    } finally {
      if (mounted) setState(() => _pushing = false);
    }
  }

  Future<void> _accept() async {
    await sl<DeliveryService>().acceptDelivery(widget.deliveryId);
    _reload();
  }

  Future<void> _reload() async {
    final d = await sl<DeliveryService>().getById(widget.deliveryId);
    setState(() => _delivery = d);
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  double? _latFromAddress(dynamic entity) {
    if (entity is Map<String, dynamic>) {
      return _asDouble(entity['latitude']);
    }
    return null;
  }

  double? _lngFromAddress(dynamic entity) {
    if (entity is Map<String, dynamic>) {
      return _asDouble(entity['longitude']);
    }
    return null;
  }

  Future<void> _updateStatus(String status) async {
    await sl<DeliveryService>().updateStatus(widget.deliveryId, {'status': status});
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final status = _delivery?['status']?.toString() ?? '';
    final role = context.watch<AuthProvider>().user?.role;
    final isDriver = role == UserRole.deliveryPersonnel;

    final currentLat = _asDouble(_delivery?['currentLatitude']) ??
        _asDouble(_delivery?['latitude']);
    final currentLng = _asDouble(_delivery?['currentLongitude']) ??
        _asDouble(_delivery?['longitude']);

    final destLat = _asDouble(_delivery?['addressLatitude']) ??
        _asDouble(_delivery?['deliveryLatitude']) ??
        _latFromAddress(_delivery?['deliveryAddressEntity']) ??
        _latFromAddress(_delivery?['deliveryAddress']);
    final destLng = _asDouble(_delivery?['addressLongitude']) ??
        _asDouble(_delivery?['deliveryLongitude']) ??
        _lngFromAddress(_delivery?['deliveryAddressEntity']) ??
        _lngFromAddress(_delivery?['deliveryAddress']);

    return MobileShell(
      title: 'Track Delivery',
      showBack: true,
      child: _delivery == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StatusBadge(label: status, status: status),
                const SizedBox(height: 16),
                if (destLat != null && destLng != null)
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(destLat, destLng),
                          zoom: 13,
                        ),
                        myLocationEnabled: false,
                        zoomControlsEnabled: false,
                        markers: {
                          Marker(
                            markerId: const MarkerId('dest'),
                            position: LatLng(destLat, destLng),
                            infoWindow: const InfoWindow(title: 'Destination'),
                          ),
                          if (currentLat != null && currentLng != null)
                            Marker(
                              markerId: const MarkerId('driver'),
                              position: LatLng(currentLat, currentLng),
                              infoWindow:
                                  const InfoWindow(title: 'Current location'),
                            ),
                        },
                      ),
                    ),
                  ),
                if (destLat != null && destLng != null)
                  const SizedBox(height: 12),
                _DetailRow('Order', _delivery!['orderNumber']),
                _DetailRow('Customer', _delivery!['customerName']),
                _DetailRow('Phone', _delivery!['customerPhone']),
                _DetailRow('Address', _delivery!['deliveryAddress']),
                const SizedBox(height: 12),
                if (isDriver)
                  SwitchListTile.adaptive(
                    value: _live,
                    title: const Text('Live tracking (push GPS)'),
                    subtitle: Text(_pushing ? 'Updating…' : 'Every 30 seconds while open'),
                    onChanged: (v) {
                      setState(() => _live = v);
                      if (v) _startPusher();
                    },
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    final lat = _asDouble(_delivery!['latitude']) ??
                        _asDouble(_delivery!['deliveryLatitude']) ??
                        _latFromAddress(_delivery!['deliveryAddressEntity']);
                    final lng = _asDouble(_delivery!['longitude']) ??
                        _asDouble(_delivery!['deliveryLongitude']) ??
                        _lngFromAddress(_delivery!['deliveryAddressEntity']);
                    final addr = _delivery!['deliveryAddress']?.toString();
                    openInMaps(
                      latitude: lat,
                      longitude: lng,
                      addressQuery: (lat == null || lng == null) ? addr : null,
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Maps'),
                ),
                const SizedBox(height: 24),
                if (status == 'ASSIGNED') ...[
                  FilledButton(
                    onPressed: _accept,
                    child: const Text('Accept Delivery'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(
                      '/deliveries/${widget.deliveryId}/reject',
                    ),
                    child: const Text('Reject'),
                  ),
                ],
                if (status == 'ASSIGNED' || status == 'PENDING') ...[
                  FilledButton.icon(
                    onPressed: () async {
                      final orderId = _delivery?['orderId']?.toString();
                      if (orderId == null) return;
                      final ok = await showPickCylindersSheet(
                        context,
                        deliveryId: widget.deliveryId,
                        orderId: orderId,
                      );
                      if (ok) _reload();
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Pick Cylinders'),
                  ),
                  const SizedBox(height: 8),
                ],
                if (isDriver) ...[
                  if (status == 'PICKED_UP')
                    FilledButton(
                      onPressed: () => _updateStatus('IN_TRANSIT'),
                      child: const Text('Mark In Transit'),
                    ),
                  if (status == 'IN_TRANSIT' || status == 'OUT_FOR_DELIVERY') ...[
                    FilledButton(
                      onPressed: () => _updateStatus('ARRIVED'),
                      child: const Text('Mark Arrived'),
                    ),
                    OutlinedButton(
                      onPressed: () => _updateStatus('FAILED'),
                      child: const Text('Mark Failed'),
                    ),
                  ],
                  if (status == 'ARRIVED') ...[
                    FilledButton(
                      onPressed: () => context.push(
                        '/deliveries/${widget.deliveryId}/proof',
                      ),
                      child: const Text('Complete — Proof of Delivery'),
                    ),
                    OutlinedButton(
                      onPressed: () => _updateStatus('FAILED'),
                      child: const Text('Mark Failed'),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

// ——— Customers ———

class CustomersListScreen extends StatelessWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      title: 'Customers',
      loadPage: (page, query) async {
        if (query != null && query.isNotEmpty) {
          final r = await sl<CustomerService>().search(query, page: page);
          return r.content;
        }
        final r = await sl<CustomerService>().getAll(page: page);
        return r.content;
      },
      itemBuilder: (item) => ListTileCard(
        title: item['name']?.toString() ?? 'Customer',
        subtitle: item['phoneNumber']?.toString(),
        onTap: () => context.push('/customers/${item['id']}'),
      ),
    );
  }
}

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Map<String, dynamic>? _customer;

  @override
  void initState() {
    super.initState();
    sl<CustomerService>().getById(widget.customerId).then((c) {
      if (mounted) setState(() => _customer = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Customer',
      child: _customer == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DetailRow('Name', _customer!['name']),
                _DetailRow('Email', _customer!['email']),
                _DetailRow('Phone', _customer!['phoneNumber']),
                _DetailRow('Type', _customer!['type']),
                _DetailRow('Orders', _customer!['totalOrders']?.toString()),
              ],
            ),
    );
  }
}

// ——— Payments ———

class PaymentsListScreen extends StatelessWidget {
  const PaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final isCustomer = role == UserRole.customer;

    return DataListScreen(
      title: 'Payments',
      loadPage: (page, _) async {
        if (isCustomer) {
          final me = await sl<CustomerService>().getMe();
          final customerId = me['id']?.toString() ?? '';
          if (customerId.isEmpty) return <Map<String, dynamic>>[];
          final r =
              await sl<PaymentService>().getByCustomer(customerId, page: page);
          return r.content;
        }
        final r = await sl<PaymentService>().getAll(page: page);
        return r.content;
      },
      searchable: false,
      itemBuilder: (item) => ListTileCard(
        title: ((item['transactionReference']?.toString().isNotEmpty ?? false)
                ? item['transactionReference']?.toString()
                : (item['paymentNumber']?.toString().isNotEmpty ?? false)
                    ? item['paymentNumber']?.toString()
                    : item['referenceNumber']?.toString()) ??
            'Payment',
        subtitle:
            '${!isCustomer ? (item['customerName'] ?? '') : ''}${!isCustomer ? ' • ' : ''}'
            '${formatCurrency(item['amount'])}'
            '${(item['orderNumber']?.toString().isNotEmpty ?? false) ? ' • #${item['orderNumber']}' : ''}',
        badge: item['status']?.toString(),
        onTap: () {
          final orderId = item['orderId']?.toString() ??
              item['order']?['id']?.toString();
          if (orderId != null && orderId.isNotEmpty) {
            context.push('/payments/$orderId/invoice');
          }
        },
      ),
    );
  }
}

// ——— Notifications ———

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return MobileShell(
      title: 'Notifications',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context
                            .read<NotificationProvider>()
                            .markAllRead();
                      },
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark all read'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context
                            .read<NotificationProvider>()
                            .refreshUnreadCount();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              labelColor: AppColors.primary,
              tabs: [
                const Tab(text: 'All'),
                Tab(text: 'Unread${unread > 0 ? " ($unread)" : ""}'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _NotificationsList(
                    loader: (page) async =>
                        (await sl<NotificationService>().getAll(page: page))
                            .content,
                  ),
                  _NotificationsList(
                    loader: (_) => sl<NotificationService>().getUnread(),
                    hidePagination: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.loader,
    this.hidePagination = false,
  });

  final Future<List<Map<String, dynamic>>> Function(int page) loader;
  final bool hidePagination;

  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      title: '',
      searchable: false,
      loadPage: (page, _) async => loader(page),
      itemBuilder: (item) => ListTileCard(
        title: item['title']?.toString() ?? 'Notification',
        subtitle: item['message']?.toString(),
        badge: item['isRead'] == true ? null : 'NEW',
        onTap: () async {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty && item['isRead'] != true) {
            await context.read<NotificationProvider>().markAsRead(id);
          }
          if (context.mounted) {
            _showNotificationDetail(context, item);
          }
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final id = item['id']?.toString() ?? '';
            if (id.isEmpty) return;
            try {
              await sl<NotificationService>().delete(id);
              if (context.mounted) {
                await context.read<NotificationProvider>().refreshUnreadCount();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification deleted')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _showNotificationDetail(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title']?.toString() ?? 'Notification',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              item['message']?.toString() ?? '',
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item['type']?.toString().isNotEmpty ?? false)
                  StatusBadge(
                    label: item['type']?.toString() ?? '',
                    status: item['type']?.toString(),
                  ),
                if (item['createdAt']?.toString().isNotEmpty ?? false)
                  Text(
                    item['createdAt']?.toString() ?? '',
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ——— Reports ———

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _inventory;
  Map<String, dynamic>? _sales;
  Map<String, dynamic>? _delivery;
  Map<String, dynamic>? _paymentRec;
  bool _loading = true;

  String _preset = 'month'; // today, week, month, quarter, year

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  ({String start, String end}) _range() {
    final now = DateTime.now();
    final end = _fmt(now);

    DateTime start;
    switch (_preset) {
      case 'today':
        start = now;
        break;
      case 'week':
        final weekday = now.weekday; // Mon=1
        start = now.subtract(Duration(days: weekday - 1));
        break;
      case 'quarter':
        final qStartMonth = (((now.month - 1) ~/ 3) * 3) + 1;
        start = DateTime(now.year, qStartMonth, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'month':
      default:
        start = DateTime(now.year, now.month, 1);
        break;
    }
    return (start: _fmt(start), end: end);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = _range();
    try {
      final inv = await sl<ReportService>().getInventoryReport();
      final sales = await sl<ReportService>().getSalesReport(r.start, r.end);
      final del = await sl<ReportService>().getDeliveryReport(r.start, r.end);
      final pay = await sl<ReportService>().getPaymentReconciliation(r.start, r.end);

      if (!mounted) return;
      setState(() {
        _inventory = inv;
        _sales = sales;
        _delivery = del;
        _paymentRec = pay;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _exportTemplate(
    BuildContext context, {
    required String template,
    required String format,
  }) async {
    final r = _range();
    try {
      final dl = switch (template) {
        'sales' => await sl<ReportService>().downloadSalesExport(
            format,
            r.start,
            r.end,
          ),
        'delivery' => await sl<ReportService>().downloadDeliveryExport(
            format,
            r.start,
            r.end,
          ),
        'inventory' => await sl<ReportService>().downloadInventoryExport(format),
        'payment' => await sl<ReportService>().downloadPaymentReconciliationExport(
            format,
            r.start,
            r.end,
          ),
        _ => throw Exception('Unknown report template'),
      };

      if (!context.mounted) return;
      await FileShare.shareBytes(
        dl.toSharedFile(),
        text: 'Report export: ${dl.filename}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Reports',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _preset,
                          decoration: const InputDecoration(
                            labelText: 'Date range',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'today', child: Text('Today')),
                            DropdownMenuItem(value: 'week', child: Text('This week')),
                            DropdownMenuItem(value: 'month', child: Text('This month')),
                            DropdownMenuItem(
                                value: 'quarter', child: Text('This quarter')),
                            DropdownMenuItem(value: 'year', child: Text('This year')),
                          ],
                          onChanged: (v) async {
                            setState(() => _preset = v ?? 'month');
                            await _load();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _templateCard(
                      context,
                      title: 'Sales report',
                      subtitle: 'Orders, revenue, product mix',
                      icon: Icons.trending_up,
                      onExport: (fmt) => _exportTemplate(
                        context,
                        template: 'sales',
                        format: fmt,
                      ),
                    ),
                    _templateCard(
                      context,
                      title: 'Inventory report',
                      subtitle: 'Warehouses & low stock snapshot',
                      icon: Icons.inventory_2_outlined,
                      onExport: (fmt) => _exportTemplate(
                        context,
                        template: 'inventory',
                        format: fmt,
                      ),
                    ),
                    _templateCard(
                      context,
                      title: 'Delivery performance',
                      subtitle: 'Completion rates & drivers',
                      icon: Icons.local_shipping_outlined,
                      onExport: (fmt) => _exportTemplate(
                        context,
                        template: 'delivery',
                        format: fmt,
                      ),
                    ),
                    _templateCard(
                      context,
                      title: 'Payment reconciliation',
                      subtitle: 'Orders vs payments variances',
                      icon: Icons.credit_card,
                      onExport: (fmt) => _exportTemplate(
                        context,
                        template: 'payment',
                        format: fmt,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                if (_sales != null || _delivery != null || _inventory != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Key metrics',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _metricRow('Net revenue', formatCurrency(_sales?['netRevenue'])),
                          _metricRow('Orders', _sales?['totalOrders']?.toString()),
                          _metricRow(
                            'Delivery completion',
                            _delivery?['completionRate'] != null
                                ? '${(_delivery!['completionRate']).toString()}%'
                                : null,
                          ),
                          _metricRow(
                            'Stock value',
                            _inventory?['totalStockValue']?.toString(),
                          ),
                          if (_paymentRec != null)
                            _metricRow(
                              'Unmatched payments',
                              _paymentRec?['unmatchedPaymentsCount']?.toString(),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.build),
                  title: const Text('Custom Report Builder'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reports/builder'),
                ),
              ],
            ),
    );
  }

  Widget _metricRow(String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
            ),
            Text(value ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _templateCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Future<void> Function(String format) onExport,
  }) {
    return SizedBox(
      width: 340,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: AppColors.mutedForeground)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => onExport('PDF'),
                    child: const Text('PDF'),
                  ),
                  OutlinedButton(
                    onPressed: () => onExport('EXCEL'),
                    child: const Text('Excel'),
                  ),
                  OutlinedButton(
                    onPressed: () => onExport('CSV'),
                    child: const Text('CSV'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ——— Settings ———

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _company;

  @override
  void initState() {
    super.initState();
    sl<SettingsService>().getCompanySettings().then((c) {
      if (mounted) setState(() => _company = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Settings',
      child: ListView(
        children: [
          if (_company != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.business, color: Colors.white),
                ),
                title: Text(_company!['name']?.toString() ?? 'Company'),
                subtitle: Text(_company!['email']?.toString() ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/company'),
              ),
            ),
          _settingsTile(context, Icons.palette_outlined, 'Appearance',
              () => context.push('/settings/appearance')),
          _settingsTile(
            context,
            Icons.tune_outlined,
            'Notification Preferences',
            () => context.push('/settings/notification-preferences'),
          ),
          _settingsTile(context, Icons.lock_outline, 'Change Password',
              () => _showChangePassword(context)),
          _settingsTile(context, Icons.people_outline, 'User Management',
              () => context.push('/settings/users')),
          _settingsTile(context, Icons.history, 'Session Activity',
              () => context.push('/settings/sessions')),
          _settingsTile(context, Icons.shield_outlined, 'Permissions',
              () => context.push('/settings/permissions')),
          _settingsTile(context, Icons.notifications_active_outlined,
              'Alert Configuration', () => context.push('/settings/alerts')),
          _settingsTile(context, Icons.email_outlined, 'Notification Templates',
              () => context.push('/settings/templates')),
          _settingsTile(context, Icons.monitor_heart_outlined, 'System Health',
              () => context.push('/settings/health')),
          _settingsTile(context, Icons.backup_outlined, 'Backup & Restore',
              () => context.push('/settings/backup')),
        ],
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) =>
      ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  void _showChangePassword(BuildContext context) {
    final old = TextEditingController();
    final newP = TextEditingController();
    final confirm = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: old,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current')),
            TextField(
                controller: newP,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New')),
            TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await sl<SettingsService>().changePassword(
                  currentPassword: old.text,
                  newPassword: newP.text,
                  confirmPassword: confirm.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

// ——— Generic list screens for remaining features ———

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});
  @override
  Widget build(BuildContext context) => DataListScreen(
        title: 'User Management',
        loadPage: (page, _) async =>
            (await sl<UserService>().getAll(page: page)).content,
        searchable: false,
        itemBuilder: (item) => ListTileCard(
          title: '${item['firstName']} ${item['lastName']}',
          subtitle: item['email']?.toString(),
          badge: item['role']?.toString(),
        ),
      );
}

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});
  @override
  Widget build(BuildContext context) => DataListScreen(
        title: 'Session Activity',
        loadPage: (page, _) async =>
            (await sl<SessionService>().getMyActivities(page: page)).content,
        searchable: false,
        itemBuilder: (item) => ListTileCard(
          title: item['action']?.toString() ?? 'Activity',
          subtitle: item['ipAddress']?.toString(),
        ),
      );
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});
  @override
  Widget build(BuildContext context) => DataListScreen(
        title: 'Alert Configuration',
        loadPage: (_, __) => sl<AlertService>().getRules(),
        searchable: false,
        itemBuilder: (item) => ListTileCard(
          title: item['name']?.toString() ?? 'Rule',
          subtitle: item['description']?.toString(),
          badge: item['isActive'] == true ? 'ON' : 'OFF',
        ),
      );
}

class CommunicationsScreen extends StatelessWidget {
  const CommunicationsScreen({super.key});
  @override
  Widget build(BuildContext context) => DataListScreen(
        title: 'Communications',
        loadPage: (page, _) async =>
            (await sl<CommunicationService>().getAll(page: page)).content,
        searchable: false,
        itemBuilder: (item) => ListTileCard(
          title: item['subject']?.toString() ??
              item['type']?.toString() ??
              'Communication',
          subtitle: item['status']?.toString(),
        ),
      );
}

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});
  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _tiers = [];

  @override
  void initState() {
    super.initState();
    Future.wait([
      sl<LoyaltyService>().getStats(),
      sl<LoyaltyService>().getTiers(),
    ]).then((r) {
      if (mounted) {
        setState(() {
          _stats = r[0] as Map<String, dynamic>;
          _tiers = r[1] as List<Map<String, dynamic>>;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Loyalty Program',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_stats != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Members: ${_stats!['totalMembers'] ?? 0}'),
              ),
            ),
          ..._tiers.map((t) => ListTile(
                title: Text(t['name']?.toString() ?? ''),
                subtitle: Text('Min points: ${t['minPoints'] ?? 0}'),
              )),
        ],
      ),
    );
  }
}

class CreditScreen extends StatelessWidget {
  const CreditScreen({super.key});
  @override
  Widget build(BuildContext context) => DataListScreen(
        title: 'Credit Management',
        loadPage: (page, _) async =>
            (await sl<CreditService>().getAccounts(page: page)).content,
        searchable: false,
        itemBuilder: (item) => ListTileCard(
          title: item['customerName']?.toString() ?? 'Account',
          subtitle: 'Balance: ${item['outstandingBalance'] ?? 0}',
          badge: item['status']?.toString(),
        ),
      );
}

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});
  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  List<Map<String, dynamic>> _services = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    Future.wait([
      sl<SystemService>().getServices(),
      sl<SystemService>().getHealthStats(),
    ]).then((r) {
      if (mounted) {
        setState(() {
          _services = r[0] as List<Map<String, dynamic>>;
          _stats = r[1] as Map<String, dynamic>;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'System Health',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_stats != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Uptime: ${_stats!['uptimePercentage'] ?? 'N/A'}%'),
              ),
            ),
          ..._services.map((s) => ListTile(
                leading: Icon(
                  s['status'] == 'UP' ? Icons.check_circle : Icons.error,
                  color: s['status'] == 'UP' ? Colors.green : Colors.red,
                ),
                title: Text(s['name']?.toString() ?? ''),
                subtitle: Text(s['status']?.toString() ?? ''),
              )),
        ],
      ),
    );
  }
}

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Backup & Restore',
      child: Center(
        child: FilledButton.icon(
          onPressed: () async {
            await sl<SystemService>().createBackup();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup started')),
              );
            }
          },
          icon: const Icon(Icons.backup),
          label: const Text('Create Backup'),
        ),
      ),
    );
  }
}

class SuppliersListScreen extends StatelessWidget {
  const SuppliersListScreen({super.key});
  @override
  Widget build(BuildContext context) => DataListScreen(
        title: 'Suppliers',
        loadPage: (page, _) async =>
            (await sl<InventoryService>().getSuppliers(page: page)).content,
        searchable: false,
        itemBuilder: (item) => ListTileCard(
          title: item['name']?.toString() ?? 'Supplier',
          subtitle: item['contactPhone']?.toString(),
        ),
      );
}

class WarehousesListScreen extends StatelessWidget {
  const WarehousesListScreen({super.key});
  @override
  Widget build(BuildContext context) => DataListScreen(
        title: 'Warehouses',
        loadPage: (_, __) => sl<InventoryService>().getWarehousesList(),
        searchable: false,
        itemBuilder: (item) => ListTileCard(
          title: item['name']?.toString() ?? 'Warehouse',
          subtitle: item['address']?.toString(),
        ),
      );
}

class ReturnsListScreen extends StatelessWidget {
  const ReturnsListScreen({super.key});
  @override
  Widget build(BuildContext context) => DataListScreen(
        title: 'Cylinder Returns',
        loadPage: (_, __) => sl<InventoryService>().getPendingReturns(),
        searchable: false,
        itemBuilder: (item) => ListTileCard(
          title: item['orderNumber']?.toString() ?? 'Return',
          subtitle: item['productName']?.toString(),
          status: item['status']?.toString(),
          onTap: () => _handleReturn(context, item),
        ),
      );

  Future<void> _handleReturn(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final id = item['id']?.toString();
    if (id == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check, color: AppColors.success),
              title: const Text('Approve return'),
              onTap: () => Navigator.pop(ctx, 'approve'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.destructive),
              title: const Text('Reject return'),
              onTap: () => Navigator.pop(ctx, 'reject'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    try {
      if (action == 'approve') {
        await sl<InventoryService>().approveReturn(id, {});
      } else {
        await sl<InventoryService>().rejectReturn(id, 'Rejected from mobile');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Return ${action}d')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _size = TextEditingController(text: 'KG_12');
  final _price = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _size.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await sl<InventoryService>().createProduct({
        'name': _name.text.trim(),
        'sku': _sku.text.trim(),
        'cylinderSize': _size.text.trim(),
        'unitPrice': double.tryParse(_price.text) ?? 0,
      });
      if (mounted) context.pop();
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
      title: 'Add Product',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: _sku,
                decoration: const InputDecoration(labelText: 'SKU')),
            TextField(
                controller: _size,
                decoration: const InputDecoration(labelText: 'Cylinder Size')),
            TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Unit Price')),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Create Product'),
            ),
          ],
        ),
      ),
    );
  }
}

class StockAdjustmentScreen extends StatefulWidget {
  const StockAdjustmentScreen({super.key});
  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _productId = TextEditingController();
  final _warehouseId = TextEditingController();
  final _qty = TextEditingController(text: '1');
  bool _loading = false;

  @override
  void dispose() {
    _productId.dispose();
    _warehouseId.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await sl<InventoryService>().adjustStock({
        'productId': _productId.text.trim(),
        'warehouseId': _warehouseId.text.trim(),
        'quantity': int.parse(_qty.text),
        'transactionType': 'ADJUSTMENT',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock adjusted')),
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
      title: 'Stock Adjustment',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _productId,
                decoration: const InputDecoration(labelText: 'Product ID')),
            TextField(
                controller: _warehouseId,
                decoration: const InputDecoration(labelText: 'Warehouse ID')),
            TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity')),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Adjust Stock'),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteOptimizationScreen extends StatefulWidget {
  const RouteOptimizationScreen({super.key});
  @override
  State<RouteOptimizationScreen> createState() => _RouteOptimizationScreenState();
}

class _RouteOptimizationScreenState extends State<RouteOptimizationScreen> {
  Map<String, dynamic>? _result;

  Future<void> _optimize() async {
    final unassigned = await sl<DeliveryService>().getUnassigned();
    if (unassigned.isEmpty) return;
    final result = await sl<DeliveryService>().optimizeRoute({
      'deliveryIds': unassigned.map((d) => d['id']).toList(),
      'criteria': 'BALANCED',
    });
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Route Optimization',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FilledButton(
              onPressed: _optimize,
              child: const Text('Optimize Routes'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text('Total distance: ${_result!['totalDistanceKm']} km'),
              Text('Duration: ${_result!['estimatedDurationMinutes']} min'),
            ],
          ],
        ),
      ),
    );
  }
}

class DriverPerformanceScreen extends StatefulWidget {
  const DriverPerformanceScreen({super.key});
  @override
  State<DriverPerformanceScreen> createState() =>
      _DriverPerformanceScreenState();
}

class _DriverPerformanceScreenState extends State<DriverPerformanceScreen> {
  List<Map<String, dynamic>> _drivers = [];

  @override
  void initState() {
    super.initState();
    sl<DeliveryService>().getAvailableDrivers().then((d) {
      if (mounted) setState(() => _drivers = d);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Driver Performance',
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _drivers.length,
        itemBuilder: (_, i) {
          final d = _drivers[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTileCard(
              title: '${d['firstName']} ${d['lastName']}',
              subtitle: 'Rating: ${d['rating'] ?? '—'} · '
                  'Deliveries: ${d['completedDeliveries'] ?? d['totalDeliveries'] ?? 0}',
            ),
          );
        },
      ),
    );
  }
}

class AssignDriverScreen extends StatelessWidget {
  const AssignDriverScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DataListScreen(
      title: 'Assign Driver',
      searchable: false,
      loadPage: (_, __) => sl<DeliveryService>().getUnassigned(),
      itemBuilder: (item) => ListTileCard(
        title: item['orderNumber']?.toString() ?? 'Delivery',
        subtitle: item['customerName']?.toString(),
        onTap: () => _showAssign(context, item),
      ),
    );
  }

  Future<void> _showAssign(BuildContext context, Map<String, dynamic> delivery) async {
    final drivers = await sl<DeliveryService>().getAvailableDrivers();
    if (!context.mounted) return;

    String? selectedDriverId;
    DateTime? scheduled;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> pickDateTime() async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: ctx,
                firstDate: now,
                lastDate: now.add(const Duration(days: 30)),
                initialDate: scheduled ?? now,
              );
              if (date == null) return;
              if (!ctx.mounted) return;
              final time = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.fromDateTime(scheduled ?? now),
              );
              if (time == null) return;
              setSheet(() {
                scheduled = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            Future<void> assign() async {
              final id = delivery['id']?.toString() ?? '';
              if (id.isEmpty || selectedDriverId == null) return;
              try {
                await sl<DeliveryService>().assignDriver(id, {
                  'driverId': selectedDriverId,
                  if (scheduled != null)
                    'scheduledDate': scheduled!.toIso8601String().split('.').first,
                });
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Driver assigned')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign driver',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order: ${delivery['orderNumber'] ?? '—'}',
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDriverId,
                    decoration: const InputDecoration(labelText: 'Driver'),
                    items: drivers
                        .map(
                          (d) => DropdownMenuItem(
                            value: d['id']?.toString(),
                            child: Text(
                              '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList()
                        .cast<DropdownMenuItem<String>>(),
                    onChanged: (v) => setSheet(() => selectedDriverId = v),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: pickDateTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      scheduled == null
                          ? 'Schedule (optional)'
                          : 'Scheduled: ${scheduled!.toLocal()}',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          onPressed: selectedDriverId == null ? null : assign,
                          child: const Text('Assign'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// CustomerSegmentsScreen & MaintenanceScreen → additional_screens.dart

class SimpleFormScreen extends StatelessWidget {
  const SimpleFormScreen({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
  });

  final String title;
  final List<String> fields;
  final Future<void> Function(Map<String, String> values) onSubmit;

  @override
  Widget build(BuildContext context) {
    final controllers =
        {for (final f in fields) f: TextEditingController()};
    return MobileShell(
      title: title,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...fields.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[f],
                  decoration: InputDecoration(labelText: f),
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                final values = {
                  for (final f in fields) f: controllers[f]!.text,
                };
                await onSubmit(values);
                if (context.mounted) context.pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value?.toString() ?? '—')),
        ],
      ),
    );
  }
}
