class AppConfig {
  // API Keys
  static const String spoonacularApiKey = 'b268027a246e40be80cedc49ecae990f';
  static const String clarifaiApiKey = 'e2c220c754424d05b8aff55c121530ee';
  
  // API URLs
  static const String spoonacularBaseUrl = 'https://api.spoonacular.com';
  static const String clarifaiBaseUrl = 'https://api.clarifai.com/v2';
  
  // Timeouts
  static const int apiTimeoutSeconds = 30;
  
  // Pagination
  static const int defaultPageSize = 10;
  
  // Debug settings
  static const bool debugLogs = true;
}
