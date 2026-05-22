import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../permissions/permissions.dart';
import 'app_routes.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.route,
    required this.icon,
    this.permission,
    this.adminOnly = false,
    this.subItems = const [],
    this.hiddenForDriver = false,
    this.hiddenForCustomer = false,
  });

  final String label;
  final String route;
  final IconData icon;
  final String? permission;
  final bool adminOnly;
  final List<NavItem> subItems;
  final bool hiddenForDriver;
  final bool hiddenForCustomer;
}

const allNavItems = [
  NavItem(
    label: 'Dashboard',
    route: AppRoutes.dashboard,
    icon: Icons.dashboard_outlined,
  ),
  NavItem(
    label: 'Inventory',
    route: AppRoutes.inventory,
    icon: Icons.inventory_2_outlined,
    permission: 'inventory.view',
    hiddenForDriver: true,
    hiddenForCustomer: true,
    subItems: [
      NavItem(
        label: 'All Products',
        route: AppRoutes.inventory,
        icon: Icons.inventory_2_outlined,
        permission: 'inventory.view',
      ),
      NavItem(
        label: 'Add Product',
        route: AppRoutes.inventoryAdd,
        icon: Icons.add,
        permission: 'inventory.manage',
      ),
      NavItem(
        label: 'Stock Adjustment',
        route: AppRoutes.inventoryStock,
        icon: Icons.tune,
        permission: 'inventory.manage',
      ),
      NavItem(
        label: 'Warehouses',
        route: AppRoutes.inventoryWarehouses,
        icon: Icons.warehouse_outlined,
        permission: 'inventory.manage',
      ),
      NavItem(
        label: 'Suppliers',
        route: AppRoutes.inventorySuppliers,
        icon: Icons.local_shipping_outlined,
        permission: 'inventory.manage',
      ),
      NavItem(
        label: 'Low Stock',
        route: AppRoutes.inventoryLowStock,
        icon: Icons.warning_amber_outlined,
        permission: 'inventory.view',
      ),
      NavItem(
        label: 'Cylinder Returns',
        route: AppRoutes.inventoryReturns,
        icon: Icons.replay,
        permission: 'inventory.manage',
      ),
      NavItem(
        label: 'QR Scanner',
        route: AppRoutes.inventoryScanner,
        icon: Icons.qr_code_scanner,
        permission: 'inventory.view',
      ),
    ],
  ),
  NavItem(
    label: 'Orders',
    route: AppRoutes.orders,
    icon: Icons.receipt_long_outlined,
    permission: 'orders.view',
    hiddenForDriver: true,
    subItems: [
      NavItem(
        label: 'All Orders',
        route: AppRoutes.orders,
        icon: Icons.receipt_long_outlined,
        permission: 'orders.view',
      ),
      NavItem(
        label: 'New Order',
        route: AppRoutes.orderNew,
        icon: Icons.add_shopping_cart,
        permission: 'orders.create',
      ),
      NavItem(
        label: 'Bulk Orders',
        route: AppRoutes.orderBulk,
        icon: Icons.upload_file_outlined,
        permission: 'orders.create',
      ),
    ],
  ),
  NavItem(
    label: 'Deliveries',
    route: AppRoutes.deliveries,
    icon: Icons.local_shipping_outlined,
    permission: 'deliveries.view',
    subItems: [
      NavItem(
        label: 'All Deliveries',
        route: AppRoutes.deliveries,
        icon: Icons.local_shipping_outlined,
        permission: 'deliveries.view',
      ),
      NavItem(
        label: 'Route Optimization',
        route: AppRoutes.deliveryRoutes,
        icon: Icons.route,
        permission: 'deliveries.manage',
      ),
      NavItem(
        label: 'Driver Performance',
        route: AppRoutes.deliveryPerformance,
        icon: Icons.emoji_events_outlined,
        permission: 'deliveries.manage',
      ),
    ],
  ),
  NavItem(
    label: 'Customers',
    route: AppRoutes.customers,
    icon: Icons.people_outline,
    permission: 'customers.view',
    hiddenForDriver: true,
    hiddenForCustomer: true,
    subItems: [
      NavItem(
        label: 'All Customers',
        route: AppRoutes.customers,
        icon: Icons.people_outline,
        permission: 'customers.view',
      ),
      NavItem(
        label: 'Segments',
        route: AppRoutes.customerSegments,
        icon: Icons.category_outlined,
        permission: 'customers.manage',
      ),
      NavItem(
        label: 'Communications',
        route: AppRoutes.customerCommunications,
        icon: Icons.chat_outlined,
        permission: 'customers.manage',
      ),
      NavItem(
        label: 'Loyalty Program',
        route: AppRoutes.customerLoyalty,
        icon: Icons.favorite_outline,
        permission: 'customers.manage',
      ),
    ],
  ),
  NavItem(
    label: 'Payments',
    route: AppRoutes.payments,
    icon: Icons.payments_outlined,
    permission: 'orders.view',
    hiddenForDriver: true,
    subItems: [
      NavItem(
        label: 'All Payments',
        route: AppRoutes.payments,
        icon: Icons.payments_outlined,
        permission: 'orders.view',
      ),
      NavItem(
        label: 'Receipts',
        route: AppRoutes.financeReceipts,
        icon: Icons.receipt_outlined,
        permission: 'orders.view',
      ),
      NavItem(
        label: 'Credit Management',
        route: AppRoutes.financeCredit,
        icon: Icons.account_balance_wallet_outlined,
        permission: 'orders.edit',
      ),
    ],
  ),
  NavItem(
    label: 'Reports',
    route: AppRoutes.reports,
    icon: Icons.bar_chart_outlined,
    permission: 'reports.view',
    hiddenForDriver: true,
    hiddenForCustomer: true,
    subItems: [
      NavItem(
        label: 'Overview',
        route: AppRoutes.reports,
        icon: Icons.bar_chart_outlined,
        permission: 'reports.view',
      ),
      NavItem(
        label: 'Report Builder',
        route: AppRoutes.reportsBuilder,
        icon: Icons.build_outlined,
        permission: 'reports.export',
      ),
    ],
  ),
  NavItem(
    label: 'Notifications',
    route: AppRoutes.notifications,
    icon: Icons.notifications_outlined,
  ),
  NavItem(
    label: 'Maintenance',
    route: AppRoutes.maintenance,
    icon: Icons.build_circle_outlined,
    permission: 'inventory.manage',
    hiddenForDriver: true,
    hiddenForCustomer: true,
  ),
  NavItem(
    label: 'Settings',
    route: AppRoutes.settings,
    icon: Icons.settings_outlined,
    permission: 'settings.view',
    subItems: [
      NavItem(
        label: 'General',
        route: AppRoutes.settings,
        icon: Icons.settings_outlined,
        permission: 'settings.view',
      ),
      NavItem(
        label: 'User Management',
        route: AppRoutes.settingsUsers,
        icon: Icons.manage_accounts_outlined,
        permission: 'users.view',
      ),
      NavItem(
        label: 'Session Activity',
        route: AppRoutes.settingsSessions,
        icon: Icons.history,
        permission: 'settings.view',
      ),
      NavItem(
        label: 'Permissions',
        route: AppRoutes.settingsPermissions,
        icon: Icons.shield_outlined,
        adminOnly: true,
      ),
      NavItem(
        label: 'Alert Configuration',
        route: AppRoutes.settingsAlerts,
        icon: Icons.notifications_active_outlined,
        permission: 'settings.manage',
      ),
      NavItem(
        label: 'Notification Templates',
        route: AppRoutes.settingsTemplates,
        icon: Icons.email_outlined,
        permission: 'settings.manage',
      ),
      NavItem(
        label: 'System Health',
        route: AppRoutes.settingsHealth,
        icon: Icons.monitor_heart_outlined,
        permission: 'settings.manage',
      ),
      NavItem(
        label: 'Backup & Restore',
        route: AppRoutes.settingsBackup,
        icon: Icons.backup_outlined,
        permission: 'settings.manage',
      ),
    ],
  ),
];

List<NavItem> filteredNavItems(UserRole role) {
  final isAdmin = role == UserRole.admin;
  final isDriver = role == UserRole.deliveryPersonnel;
  final isCustomer = role == UserRole.customer;

  bool canSee(NavItem item) {
    if (item.adminOnly && !isAdmin) return false;
    if (isDriver && item.hiddenForDriver) return false;
    if (isCustomer && item.hiddenForCustomer) return false;
    if (item.permission != null && !hasPermission(role, item.permission!)) {
      return false;
    }
    return true;
  }

  return allNavItems
      .where(canSee)
      .map((item) {
        final subs = item.subItems.where(canSee).toList();
        return NavItem(
          label: isCustomer && item.label == 'Settings'
              ? 'My Account'
              : item.label,
          route: item.route,
          icon: item.icon,
          permission: item.permission,
          adminOnly: item.adminOnly,
          subItems: subs
              .map((s) => NavItem(
                    label: isCustomer &&
                            item.label == 'Settings' &&
                            s.label == 'General'
                        ? 'My Profile'
                        : s.label,
                    route: s.route,
                    icon: s.icon,
                    permission: s.permission,
                    adminOnly: s.adminOnly,
                  ))
              .toList(),
        );
      })
      .where((item) => item.subItems.isEmpty || item.subItems.isNotEmpty)
      .toList();
}
