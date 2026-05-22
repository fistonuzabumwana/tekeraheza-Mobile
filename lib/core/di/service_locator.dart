import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../storage/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/customer_service.dart';
import '../../services/delivery_service.dart';
import '../../services/inventory_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/report_service.dart';
import '../../services/settings_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../services/system_service.dart';
import '../../services/credit_service.dart';
import '../../services/loyalty_service.dart';
import '../../services/communication_service.dart';
import '../../services/alert_service.dart';
import '../../services/session_service.dart';
import '../../services/segment_service.dart';
import '../../services/template_service.dart';
import '../../services/receipt_service.dart';
import '../../services/permission_service.dart';
import '../../services/custom_report_service.dart';
import '../../services/maintenance_service.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton(StorageService.new);
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton(() => AuthService(sl(), sl()));
  sl.registerLazySingleton(() => OrderService(sl()));
  sl.registerLazySingleton(() => DeliveryService(sl()));
  sl.registerLazySingleton(() => InventoryService(sl()));
  sl.registerLazySingleton(() => CustomerService(sl()));
  sl.registerLazySingleton(() => PaymentService(sl()));
  sl.registerLazySingleton(() => NotificationService(sl()));
  sl.registerLazySingleton(() => ReportService(sl()));
  sl.registerLazySingleton(() => SettingsService(sl()));
  sl.registerLazySingleton(() => UserService(sl()));
  sl.registerLazySingleton(() => LocationService(sl()));
  sl.registerLazySingleton(() => SystemService(sl()));
  sl.registerLazySingleton(() => CreditService(sl()));
  sl.registerLazySingleton(() => LoyaltyService(sl()));
  sl.registerLazySingleton(() => CommunicationService(sl()));
  sl.registerLazySingleton(() => AlertService(sl()));
  sl.registerLazySingleton(() => SessionService(sl()));
  sl.registerLazySingleton(() => SegmentService(sl()));
  sl.registerLazySingleton(() => TemplateService(sl()));
  sl.registerLazySingleton(() => ReceiptService(sl()));
  sl.registerLazySingleton(() => PermissionService(sl()));
  sl.registerLazySingleton(() => CustomReportService(sl()));
  sl.registerLazySingleton(() => MaintenanceService(sl()));
}
