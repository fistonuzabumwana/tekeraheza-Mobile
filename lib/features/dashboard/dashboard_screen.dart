import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/widgets/mobile_shell.dart';
import '../../providers/auth_provider.dart';
import '../../services/delivery_service.dart';
import '../../services/report_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await sl<ReportService>().getDashboardStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final isDriver = user.role == UserRole.deliveryPersonnel;
    final isCustomer = user.role == UserRole.customer;

    return MobileShell(
      title: 'Dashboard',
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Hello, ${user.firstName}!',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCustomer
                        ? 'Order LPG gas and track your deliveries.'
                        : isDriver
                            ? 'Manage your active deliveries today.'
                            : 'Overview of your distribution operations.',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  if (_stats != null && !isDriver) ...[
                    _StatGrid(stats: _stats!),
                    const SizedBox(height: 24),
                  ],
                  if (isCustomer) ...[
                    _QuickActionCard(
                      title: 'Order Gas',
                      subtitle: 'Place a new LPG order',
                      icon: Icons.local_gas_station,
                      onTap: () => context.push('/orders/new'),
                    ),
                    const SizedBox(height: 12),
                    _QuickActionCard(
                      title: 'My Orders',
                      subtitle: 'Track order status',
                      icon: Icons.receipt_long,
                      onTap: () => context.push('/orders'),
                    ),
                  ] else if (isDriver) ...[
                    _DriverSection(),
                  ] else ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MiniAction(
                          label: 'New Order',
                          icon: Icons.add_shopping_cart,
                          onTap: () => context.push('/orders/new'),
                        ),
                        _MiniAction(
                          label: 'Inventory',
                          icon: Icons.inventory_2,
                          onTap: () => context.push('/inventory'),
                        ),
                        _MiniAction(
                          label: 'Deliveries',
                          icon: Icons.local_shipping,
                          onTap: () => context.push('/deliveries'),
                        ),
                        _MiniAction(
                          label: 'Reports',
                          icon: Icons.bar_chart,
                          onTap: () => context.push('/reports'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Orders', '${stats['totalOrders'] ?? 0}', Icons.receipt_long),
      ('Revenue', formatCurrency(stats['totalRevenue']), Icons.payments),
      ('Customers', '${stats['totalCustomers'] ?? 0}', Icons.people),
      ('Deliveries', '${stats['activeDeliveries'] ?? 0}', Icons.local_shipping),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items
          .map(
            (e) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(e.$3, color: AppColors.primary),
                    const Spacer(),
                    Text(
                      e.$2,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(e.$1, style: GoogleFonts.outfit(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 32, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverSection extends StatefulWidget {
  @override
  State<_DriverSection> createState() => _DriverSectionState();
}

class _DriverSectionState extends State<_DriverSection> {
  List<Map<String, dynamic>> _deliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await sl<DeliveryService>().getMyDeliveries();
      setState(() {
        _deliveries = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Deliveries',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (_deliveries.isEmpty)
          const Text('No active deliveries')
        else
          ..._deliveries.take(5).map(
                (d) => Card(
                  child: ListTile(
                    title: Text(d['orderNumber']?.toString() ?? 'Delivery'),
                    subtitle: Text(d['deliveryAddress']?.toString() ?? ''),
                    trailing: Text(d['status']?.toString() ?? ''),
                    onTap: () => context.push('/deliveries/${d['id']}/track'),
                  ),
                ),
              ),
      ],
    );
  }
}
