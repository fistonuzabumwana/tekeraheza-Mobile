import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/location_selector.dart';
import '../../core/widgets/map_pin_picker_screen.dart';
import '../../core/widgets/mobile_shell.dart';
import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../services/inventory_service.dart';
import '../../services/order_service.dart';

class _LineItem {
  _LineItem({required this.productId, required this.quantity});
  String productId;
  int quantity;
}

/// Multi-step new order: customer (staff) → line items → payment & notes.
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _page = PageController();
  int _step = 0;

  final _search = TextEditingController();
  List<Map<String, dynamic>> _customerResults = [];
  Map<String, dynamic>? _selectedCustomer;
  String? _selectedAddressId;

  List<Map<String, dynamic>> _products = [];
  final List<_LineItem> _lines = [];

  List<Map<String, dynamic>> _warehouses = [];
  String? _selectedWarehouseId;
  String _orderType = 'REFILL';

  String _paymentMethod = 'CASH';
  final _notes = TextEditingController();
  final _deliveryFee = TextEditingController(text: '0');
  bool _loading = false;

  final _newAddressLabel = TextEditingController(text: 'Home');
  final _newStreet = TextEditingController();
  LocationValues _newLocation = const LocationValues();
  double? _newLat;
  double? _newLng;

  static const _paymentMethods = [
    'CASH',
    'MOBILE_MONEY',
    'BANK_TRANSFER',
    'CARD',
    'CREDIT',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadWarehouses();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCustomerForRole();
    });
  }

  Future<void> _loadProducts() async {
    final r = await sl<InventoryService>().getProducts(size: 100);
    if (mounted) {
      setState(() {
        _products = r.content;
        if (_lines.isEmpty && _products.isNotEmpty) {
          _lines.add(_LineItem(
            productId: _products.first['id']!.toString(),
            quantity: 1,
          ));
        }
      });
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final w = await sl<InventoryService>().getWarehousesList();
      if (!mounted) return;
      setState(() {
        _warehouses = w;
        _selectedWarehouseId ??=
            w.isNotEmpty ? w.first['id']?.toString() : null;
      });
    } catch (_) {}
  }

  Future<void> _initCustomerForRole() async {
    final role = context.read<AuthProvider>().user?.role;
    if (role == UserRole.customer) {
      try {
        final me = await sl<CustomerService>().getMe();
        if (!mounted) return;
        setState(() {
          _selectedCustomer = me;
          final addresses = (me['addresses'] as List?)?.cast<dynamic>() ?? [];
          if (addresses.isNotEmpty) {
            final primary = addresses.firstWhere(
              (a) => (a as Map)['isPrimary'] == true,
              orElse: () => addresses.first,
            ) as Map;
            _selectedAddressId = primary['id']?.toString();
          }
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _search.dispose();
    _notes.dispose();
    _deliveryFee.dispose();
    _newAddressLabel.dispose();
    _newStreet.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers() async {
    final q = _search.text.trim();
    if (q.length < 2) return;
    final r = await sl<CustomerService>().search(q, page: 0);
    if (mounted) setState(() => _customerResults = r.content);
  }

  bool get _canProceedStep0 {
    final role = context.read<AuthProvider>().user?.role;
    if (role == UserRole.customer) return _selectedCustomer != null;
    return _selectedCustomer != null;
  }

  bool get _hasValidLines =>
      _lines.isNotEmpty &&
      _lines.every((l) => l.productId.isNotEmpty && l.quantity > 0);

  bool get _hasSelectedDeliveryAddress =>
      _selectedCustomer != null &&
      ((_selectedAddressId?.isNotEmpty ?? false) ||
          ((context.read<AuthProvider>().user?.role != UserRole.customer)));

  Future<void> _submit() async {
    if (_selectedCustomer == null || !_hasValidLines) return;
    if ((_selectedWarehouseId?.isEmpty ?? true)) return;
    if (!_hasSelectedDeliveryAddress) return;
    setState(() => _loading = true);
    try {
      await sl<OrderService>().create({
        'customerId': _selectedCustomer!['id'],
        'warehouseId': _selectedWarehouseId,
        'orderType': _orderType,
        'items': _lines
            .map((e) => {
                  'productId': e.productId,
                  'quantity': e.quantity,
                })
            .toList(),
        'paymentMethod': _paymentMethod,
        'isDelivery': true,
        if (_selectedAddressId != null && _selectedAddressId!.isNotEmpty)
          'deliveryAddressId': _selectedAddressId,
        'deliveryNotes':
            _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'deliveryFee': double.tryParse(_deliveryFee.text) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created')),
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
    final role = context.watch<AuthProvider>().user?.role;
    final isCustomer = role == UserRole.customer;

    return MobileShell(
      title: 'New Order',
      showBack: true,
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              final active = i == _step;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              ['Customer', 'Items', 'Payment'][_step],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCustomerStep(isCustomer),
                _buildItemsStep(),
                _buildPaymentStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() => _step--);
                              _page.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            },
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (_step == 0) {
                              if (!_canProceedStep0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Select a customer'),
                                  ),
                                );
                                return;
                              }
                              if (isCustomer && !_hasSelectedDeliveryAddress) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Select or add a delivery address'),
                                  ),
                                );
                                return;
                              }
                            } else if (_step == 1) {
                              if (!_hasValidLines) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Add at least one valid line'),
                                  ),
                                );
                                return;
                              }
                            }
                            if (_step < 2) {
                              setState(() => _step++);
                              _page.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            } else {
                              _submit();
                            }
                          },
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_step < 2 ? 'Next' : 'Place order'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStep(bool isCustomer) {
    if (isCustomer && _selectedCustomer != null) {
      final addresses =
          (_selectedCustomer!['addresses'] as List?)?.cast<dynamic>() ?? [];
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(_selectedCustomer!['name']?.toString() ?? 'You'),
            subtitle: Text(_selectedCustomer!['email']?.toString() ?? ''),
          ),
          const Text('Ordering for your account.', style: TextStyle(color: AppColors.mutedForeground)),
          const SizedBox(height: 16),
          Text(
            'Delivery Location',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (addresses.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No delivery address found.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _openAddAddressDialog,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add address & pin on map'),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedAddressId,
                      decoration:
                          const InputDecoration(labelText: 'Delivery address'),
                      items: addresses
                          .map((a) {
                            final m = a as Map;
                            final id = m['id']?.toString() ?? '';
                            final label = (m['label']?.toString().trim().isNotEmpty ??
                                    false)
                                ? m['label'].toString()
                                : 'Address';
                            final district = m['district']?.toString() ?? '';
                            final sector = m['sector']?.toString() ?? '';
                            final street = m['streetAddress']?.toString() ??
                                m['addressLine1']?.toString() ??
                                '';
                            return DropdownMenuItem(
                              value: id,
                              child: Text(
                                '$label • $district${sector.isNotEmpty ? ", $sector" : ""}${street.isNotEmpty ? " • $street" : ""}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .toList()
                          .cast<DropdownMenuItem<String>>(),
                      onChanged: (v) => setState(() => _selectedAddressId = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openAddAddressDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add new address'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: 'Search customer (name, email, phone)',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searchCustomers,
            ),
          ),
          onSubmitted: (_) => _searchCustomers(),
        ),
        const SizedBox(height: 12),
        ..._customerResults.map(
          (c) => Card(
            child: ListTile(
              title: Text(c['name']?.toString() ?? ''),
              subtitle: Text(c['phoneNumber']?.toString() ?? ''),
              trailing: _selectedCustomer?['id'] == c['id']
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () => setState(() => _selectedCustomer = c),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: (_selectedWarehouseId?.isNotEmpty ?? false)
                      ? _selectedWarehouseId
                      : null,
                  decoration: const InputDecoration(labelText: 'Warehouse'),
                  items: _warehouses
                      .map(
                        (w) => DropdownMenuItem(
                          value: w['id']?.toString() ?? '',
                          child: Text(
                            '${w['name'] ?? 'Warehouse'}'
                            '${(w['district']?.toString().isNotEmpty ?? false) ? " • ${w['district']}" : ""}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList()
                      .cast<DropdownMenuItem<String>>(),
                  onChanged: (v) => setState(() => _selectedWarehouseId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _orderType,
                  decoration: const InputDecoration(labelText: 'Order type'),
                  items: const [
                    DropdownMenuItem(value: 'REFILL', child: Text('Refill')),
                    DropdownMenuItem(
                        value: 'NEW_CYLINDER', child: Text('New cylinder')),
                  ],
                  onChanged: (v) =>
                      setState(() => _orderType = v ?? 'REFILL'),
                ),
              ],
            ),
          ),
        ),
        ..._lines.asMap().entries.map((e) {
          final idx = e.key;
          final line = e.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: line.productId,
                          decoration: const InputDecoration(
                            labelText: 'Product',
                          ),
                          items: _products
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p['id']!.toString(),
                                  child: Text(
                                    p['name']?.toString() ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => line.productId = v);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _lines.length <= 1
                            ? null
                            : () => setState(() => _lines.removeAt(idx)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Quantity: '),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: line.quantity <= 1
                            ? null
                            : () => setState(() => line.quantity--),
                      ),
                      Text('${line.quantity}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => line.quantity++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: _products.isEmpty
              ? null
              : () => setState(() {
                    _lines.add(_LineItem(
                      productId: _products.first['id']!.toString(),
                      quantity: 1,
                    ));
                  }),
          icon: const Icon(Icons.add),
          label: const Text('Add line'),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          value: _paymentMethod,
          decoration: const InputDecoration(labelText: 'Payment method'),
          items: _paymentMethods
              .map(
                (m) => DropdownMenuItem(value: m, child: Text(m)),
              )
              .toList(),
          onChanged: (v) => setState(() => _paymentMethod = v ?? 'CASH'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deliveryFee,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Delivery fee (RWF)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Delivery notes',
          ),
        ),
      ],
    );
  }

  Future<void> _openAddAddressDialog() async {
    _newStreet.text = '';
    _newLocation = const LocationValues();
    _newLat = null;
    _newLng = null;

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
              Future<void> pickOnMap() async {
                final res = await Navigator.of(ctx).push<MapPinPickerResult>(
                  MaterialPageRoute(
                    builder: (_) => MapPinPickerScreen(
                      initial: (_newLat != null && _newLng != null)
                          ? LatLng(_newLat!, _newLng!)
                          : null,
                    ),
                  ),
                );
                if (res == null) return;
                setSheet(() {
                  _newLat = res.latitude;
                  _newLng = res.longitude;
                });
              }

              Future<void> save() async {
                if (_selectedCustomer == null) return;
                final customerId = _selectedCustomer!['id']?.toString() ?? '';
                if (customerId.isEmpty) return;

                if (_newStreet.text.trim().isEmpty ||
                    (_newLocation.district?.isEmpty ?? true)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Street/landmark and district are required'),
                    ),
                  );
                  return;
                }

                try {
                  final created = await sl<CustomerService>().addAddress(
                    customerId,
                    {
                      'label': _newAddressLabel.text.trim().isEmpty
                          ? 'Home'
                          : _newAddressLabel.text.trim(),
                      'streetAddress': _newStreet.text.trim(),
                      'province': _newLocation.province,
                      'district': _newLocation.district,
                      'sector': _newLocation.sector,
                      'cell': _newLocation.cell,
                      'village': _newLocation.village,
                      if (_newLat != null) 'latitude': _newLat,
                      if (_newLng != null) 'longitude': _newLng,
                      'isPrimary': true,
                    },
                  );

                  if (!mounted) return;
                  final addresses = (_selectedCustomer!['addresses'] as List?)
                          ?.cast<dynamic>()
                          .toList() ??
                      <dynamic>[];
                  addresses.add(created);
                  setState(() {
                    _selectedCustomer = {
                      ..._selectedCustomer!,
                      'addresses': addresses,
                    };
                    _selectedAddressId = created['id']?.toString();
                  });

                  if (context.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add delivery address',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newAddressLabel,
                      decoration: const InputDecoration(
                        labelText: 'Label (Home, Office)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newStreet,
                      decoration: const InputDecoration(
                        labelText: 'Street / Landmark',
                      ),
                    ),
                    const SizedBox(height: 12),
                    LocationSelector(
                      values: _newLocation,
                      onChanged: (v) => setSheet(() => _newLocation = v),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Map pin',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: pickOnMap,
                                    icon: const Icon(Icons.map_outlined),
                                    label: Text(
                                      _newLat == null
                                          ? 'Pick on map'
                                          : 'Change pin',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_newLat != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Selected: ${_newLat!.toStringAsFixed(6)}, ${_newLng!.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                      color: AppColors.mutedForeground),
                                ),
                              ),
                          ],
                        ),
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
                            onPressed: save,
                            child: const Text('Save address'),
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
  }
}
