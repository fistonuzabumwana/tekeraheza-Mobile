import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/two_factor_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/orders/bulk_orders_screen.dart';
import '../../features/orders/new_order_screen.dart';
import '../../features/screens/additional_screens.dart';
import '../../features/screens/feature_screens.dart';
import '../../providers/auth_provider.dart';

GoRouter createAppRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.isLoading) return null;
      final isAuth = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' ||
          loc == '/signup' ||
          loc.startsWith('/forgot-password') ||
          loc.startsWith('/reset-password') ||
          loc.startsWith('/verify-code') ||
          loc.startsWith('/two-factor');
      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && loc == '/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/verify-code',
        builder: (_, __) => const VerifyCodeScreen(),
      ),
      GoRoute(
        path: '/two-factor',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TwoFactorScreen(
            token: extra['token'] as String? ?? '',
            type: extra['type'] as String?,
          );
        },
      ),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),

      // Inventory — static routes before :id
      GoRoute(path: '/inventory', builder: (_, __) => const InventoryListScreen()),
      GoRoute(
        path: '/inventory/add-product',
        builder: (_, __) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/inventory/stock-adjustment',
        builder: (_, __) => const StockAdjustmentScreen(),
      ),
      GoRoute(
        path: '/inventory/suppliers',
        builder: (_, __) => const SuppliersListScreen(),
      ),
      GoRoute(
        path: '/inventory/warehouses',
        builder: (_, __) => const WarehousesListScreen(),
      ),
      GoRoute(
        path: '/inventory/low-stock',
        builder: (_, __) => const LowStockScreen(),
      ),
      GoRoute(
        path: '/inventory/returns',
        builder: (_, __) => const ReturnsListScreen(),
      ),
      GoRoute(
        path: '/inventory/scanner',
        builder: (_, __) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/inventory/products/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/inventory/cylinders/:id',
        builder: (_, state) =>
            CylinderDetailScreen(cylinderId: state.pathParameters['id']!),
      ),

      // Orders
      GoRoute(path: '/orders', builder: (_, __) => const OrdersListScreen()),
      GoRoute(path: '/orders/new', builder: (_, __) => const NewOrderScreen()),
      GoRoute(
        path: '/orders/bulk',
        builder: (_, __) => const BulkOrdersScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),

      // Deliveries — static before :id
      GoRoute(
        path: '/deliveries',
        builder: (_, __) => const DeliveriesListScreen(),
      ),
      GoRoute(
        path: '/deliveries/assign',
        builder: (_, __) => const AssignDriverScreen(),
      ),
      GoRoute(
        path: '/deliveries/routes',
        builder: (_, __) => const RouteOptimizationScreen(),
      ),
      GoRoute(
        path: '/deliveries/performance',
        builder: (_, __) => const DriverPerformanceScreen(),
      ),
      GoRoute(
        path: '/deliveries/:id/track',
        builder: (_, state) =>
            DeliveryTrackScreen(deliveryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/deliveries/:id/proof',
        builder: (_, state) =>
            ProofOfDeliveryScreen(deliveryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/deliveries/:id/accept',
        builder: (_, state) => DeliveryResponseScreen(
          deliveryId: state.pathParameters['id']!,
          accept: true,
        ),
      ),
      GoRoute(
        path: '/deliveries/:id/reject',
        builder: (_, state) => DeliveryResponseScreen(
          deliveryId: state.pathParameters['id']!,
          accept: false,
        ),
      ),

      // Customers — static before :id
      GoRoute(
        path: '/customers',
        builder: (_, __) => const CustomersListScreen(),
      ),
      GoRoute(
        path: '/customers/segments',
        builder: (_, __) => const CustomerSegmentsScreen(),
      ),
      GoRoute(
        path: '/customers/communications',
        builder: (_, __) => const CommunicationsScreen(),
      ),
      GoRoute(
        path: '/customers/loyalty',
        builder: (_, __) => const LoyaltyScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (_, state) =>
            CustomerDetailScreen(customerId: state.pathParameters['id']!),
      ),

      // Payments & finance
      GoRoute(path: '/payments', builder: (_, __) => const PaymentsListScreen()),
      GoRoute(
        path: '/payments/:id/invoice',
        builder: (_, state) =>
            InvoiceScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/finance/receipts',
        builder: (_, __) => const ReceiptsScreen(),
      ),
      GoRoute(path: '/finance/credit', builder: (_, __) => const CreditScreen()),

      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(
        path: '/reports/builder',
        builder: (_, __) => const ReportBuilderScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (_, __) => const EnhancedMaintenanceScreen(),
      ),

      // Settings
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
        path: '/settings/company',
        builder: (_, __) => const CompanySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notification-preferences',
        builder: (_, __) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/settings/appearance',
        builder: (_, __) => const AppearanceSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/users',
        builder: (_, __) => const UsersListScreen(),
      ),
      GoRoute(
        path: '/settings/sessions',
        builder: (_, __) => const SessionsScreen(),
      ),
      GoRoute(
        path: '/settings/permissions',
        builder: (_, __) => const PermissionGroupsScreen(),
      ),
      GoRoute(
        path: '/settings/alerts',
        builder: (_, __) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/settings/templates',
        builder: (_, __) => const NotificationTemplatesScreen(),
      ),
      GoRoute(
        path: '/settings/health',
        builder: (_, __) => const SystemHealthScreen(),
      ),
      GoRoute(
        path: '/settings/backup',
        builder: (_, __) => const BackupScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}
