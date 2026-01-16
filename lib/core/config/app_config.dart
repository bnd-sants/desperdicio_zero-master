import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get spoonacularApiKey => dotenv.env['SPOONACULAR_API_KEY'] ?? '';
  static String get clarifaiApiKey => dotenv.env['CLARIFAI_API_KEY'] ?? '';
  static const String spoonacularBaseUrl = 'https://api.spoonacular.com';
  static const String clarifaiBaseUrl = 'https://api.clarifai.com/v2';
  static const int apiTimeoutSeconds = 30;
  static const int defaultPageSize = 10;
  static bool get debugLogs => (dotenv.env['DEBUG'] ?? '').toLowerCase() == 'true';
}
