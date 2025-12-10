class ApiConfig {
  // Get your API key from https://spoonacular.com/food-api/console#Dashboard
  // In a production app, this should be stored securely and not hardcoded
  static const String spoonacularApiKey = 'b268027a246e40be80cedc49ecae990f';
  static const String baseUrl = 'https://api.spoonacular.com/recipes';
  
  // Endpoints
  static String findRecipesByIngredients({required String ingredients, int number = 10}) {
    return '/findByIngredients?apiKey=$spoonacularApiKey&ingredients=$ingredients&number=$number&ranking=2&ignorePantry=true';
  }
  
  static String getRecipeInformation(int id) {
    return '/$id/information?apiKey=$spoonacularApiKey&includeNutrition=true';
  }
}
