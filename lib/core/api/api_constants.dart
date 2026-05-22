class ApiConstants {
  /// AWS EC2 hosted tekeraheza-backend (context-path: /api)
  static const String baseUrl = 'https://api.tekeraheza.systems/api';

  static const String login = '/auth/login';
  static const String login2fa = '/auth/login/2fa';
  static const String login2faResend = '/auth/login/2fa/resend';
  static const String refreshToken = '/auth/refresh-token';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
}
