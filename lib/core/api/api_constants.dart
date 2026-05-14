class ApiConstants {
  // Use your local IP address for physical device testing
  // Use 10.0.2.2 for Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';
  
  // Endpoints
  static const String login = '/auth/login';
  static const String products = '/products';
  static const String orders = '/orders';
  static const String driverDeliveries = '/deliveries/driver';
}
