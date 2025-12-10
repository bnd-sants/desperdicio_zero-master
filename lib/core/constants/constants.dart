/// API endpoints
class ApiEndpoints {
  static const String baseUrl = 'https://api.example.com';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String products = '/products';
  // Add more endpoints as needed
}

/// App constants
class AppConstants {
  static const String appName = 'Desperdício Zero';
  static const String appVersion = '1.0.0';
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 30;
  // Add more app-wide constants as needed
}

/// Local storage keys
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userData = 'user_data';
  static const String themeMode = 'theme_mode';
  // Add more storage keys as needed
}
