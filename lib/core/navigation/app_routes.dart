class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyCode = '/verify-code';
  static const twoFactor = '/two-factor';
  static const unauthorized = '/unauthorized';

  static const dashboard = '/dashboard';
  static const inventory = '/inventory';
  static const inventoryAdd = '/inventory/add-product';
  static const inventoryStock = '/inventory/stock-adjustment';
  static const inventorySuppliers = '/inventory/suppliers';
  static const inventoryWarehouses = '/inventory/warehouses';
  static const inventoryLowStock = '/inventory/low-stock';
  static const inventoryReturns = '/inventory/returns';
  static const inventoryScanner = '/inventory/scanner';
  static const productDetail = '/inventory/products/:id';
  static const cylinderDetail = '/inventory/cylinders/:id';

  static const orders = '/orders';
  static const orderNew = '/orders/new';
  static const orderBulk = '/orders/bulk';
  static const orderDetail = '/orders/:id';

  static const deliveries = '/deliveries';
  static const deliveryAssign = '/deliveries/assign';
  static const deliveryRoutes = '/deliveries/routes';
  static const deliveryPerformance = '/deliveries/performance';
  static const deliveryTrack = '/deliveries/:id/track';
  static const deliveryProof = '/deliveries/:id/proof';

  static const customers = '/customers';
  static const customerDetail = '/customers/:id';
  static const customerSegments = '/customers/segments';
  static const customerCommunications = '/customers/communications';
  static const customerLoyalty = '/customers/loyalty';

  static const payments = '/payments';
  static const paymentInvoice = '/payments/:id/invoice';
  static const financeReceipts = '/finance/receipts';
  static const financeCredit = '/finance/credit';

  static const reports = '/reports';
  static const reportsBuilder = '/reports/builder';
  static const notifications = '/notifications';
  static const maintenance = '/maintenance';

  static const settings = '/settings';
  static const settingsCompany = '/settings/company';
  static const settingsNotificationPrefs = '/settings/notification-preferences';
  static const settingsAppearance = '/settings/appearance';
  static const settingsUsers = '/settings/users';
  static const settingsSessions = '/settings/sessions';
  static const settingsPermissions = '/settings/permissions';
  static const settingsAlerts = '/settings/alerts';
  static const settingsTemplates = '/settings/templates';
  static const settingsHealth = '/settings/health';
  static const settingsBackup = '/settings/backup';
}
