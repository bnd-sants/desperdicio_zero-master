// lib/services/food_recognition_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FoodRecognitionService {
  // Configurações da API
  static const String _spoonacularApiKey = 'b268027a246e40be80cedc49ecae990f';
  static const String _clarifaiApiKey = 'e2c220c754424d05b8aff55c121530ee';

  // IDs necessários para Clarifai
  static const String _clarifaiUserId = '2ue7e5oumt383';
  static const String _clarifaiAppId = 'food-recognition-app';

  // URLs das APIs
  static const String _spoonacularUrl = 'https://api.spoonacular.com/food/images/classify';
  static const String _clarifaiUrl = 'https://api.clarifai.com/v2/models/food-item-recognition/versions/1d5fd481e0cf4826aa72ec3ff049e044/outputs';

  // Método para capturar imagem da câmera
  static Future<File?> captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Método para selecionar imagem da galeria
  static Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Método principal para reconhecer alimento
  static Future<Map<String, dynamic>?> recognizeFood(File imageFile) async {
    try {
      // 1. Tenta Spoonacular API (mais específica para alimentos)
      if (_spoonacularApiKey != 'YOUR_SPOONACULAR_API_KEY_HERE' && _spoonacularApiKey.isNotEmpty) {
        final result = await _recognizeWithSpoonacular(imageFile);
        if (result != null) return result;
      }

      // 2. Tenta Clarifai API (boa para reconhecimento geral)
      if (_clarifaiApiKey != 'YOUR_CLARIFAI_API_KEY_HERE' && _clarifaiApiKey.isNotEmpty) {
        final result = await _recognizeWithClarifai(imageFile);
        if (result != null) return result;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Reconhecimento usando Spoonacular API
  static Future<Map<String, dynamic>?> _recognizeWithSpoonacular(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_spoonacularUrl?apiKey=$_spoonacularApiKey'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = jsonDecode(responseData);

      if (response.statusCode == 200 && result.isNotEmpty) {
        final foodName = result[0]['name'] ?? 'Alimento não identificado';

        // Busca informações nutricionais detalhadas
        final nutritionInfo = await getNutritionInfo(foodName);

        return {
          'name': foodName,
          'calories': nutritionInfo?['calories'] ?? '0',
          'carbs': nutritionInfo?['carbs'] ?? '0',
          'protein': nutritionInfo?['protein'] ?? '0',
          'fat': nutritionInfo?['fat'] ?? '0',
        };
      }
    } catch (e) {
      // Erro silencioso
    }
    return null;
  }

  // Reconhecimento usando Clarifai API
  static Future<Map<String, dynamic>?> _recognizeWithClarifai(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_clarifaiUrl),
        headers: {
          'Authorization': 'Key $_clarifaiApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_app_id': {
            'user_id': _clarifaiUserId,
            'app_id': _clarifaiAppId,
          },
          'inputs': [
            {
              'data': {
                'image': {
                  'base64': base64Image,
                }
              }
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final concepts = result['outputs'][0]['data']['concepts'];

        if (concepts.isNotEmpty) {
          final topConcept = concepts[0];
          final foodName = topConcept['name'] ?? 'Alimento não identificado';

          // Tenta buscar informações nutricionais
          final nutritionInfo = await getNutritionInfo(foodName);

          return {
            'name': foodName,
            'calories': nutritionInfo?['calories'] ?? '0',
            'carbs': nutritionInfo?['carbs'] ?? '0',
            'protein': nutritionInfo?['protein'] ?? '0',
            'fat': nutritionInfo?['fat'] ?? '0',
          };
        }
      }
    } catch (e) {
      // Erro silencioso
    }
    return null;
  }

  // Método para obter informações nutricionais de um alimento específico
  static Future<Map<String, dynamic>?> getNutritionInfo(String foodName) async {
    try {
      if (_spoonacularApiKey != 'YOUR_SPOONACULAR_API_KEY_HERE' && _spoonacularApiKey.isNotEmpty) {
        // Primeiro tenta buscar o ID do ingrediente
        final searchResponse = await http.get(
          Uri.parse('https://api.spoonacular.com/food/ingredients/search?query=$foodName&apiKey=$_spoonacularApiKey'),
        );

        if (searchResponse.statusCode == 200) {
          final searchResult = jsonDecode(searchResponse.body);
          if (searchResult['results'].isNotEmpty) {
            final ingredientId = searchResult['results'][0]['id'];

            // Busca informações nutricionais detalhadas usando o ID
            final nutritionResponse = await http.get(
              Uri.parse('https://api.spoonacular.com/food/ingredients/$ingredientId/information?amount=100&unit=grams&apiKey=$_spoonacularApiKey'),
            );

            if (nutritionResponse.statusCode == 200) {
              final nutritionResult = jsonDecode(nutritionResponse.body);
              return {
                'name': nutritionResult['name'] ?? foodName,
                'calories': nutritionResult['nutrition']?['nutrients']?.firstWhere(
                  (nutrient) => nutrient['name'] == 'Calories',
                  orElse: () => {'amount': 0}
                )['amount']?.toString() ?? '0',
                'carbs': nutritionResult['nutrition']?['nutrients']?.firstWhere(
                  (nutrient) => nutrient['name'] == 'Carbohydrates',
                  orElse: () => {'amount': 0}
                )['amount']?.toString() ?? '0',
                'protein': nutritionResult['nutrition']?['nutrients']?.firstWhere(
                  (nutrient) => nutrient['name'] == 'Protein',
                  orElse: () => {'amount': 0}
                )['amount']?.toString() ?? '0',
                'fat': nutritionResult['nutrition']?['nutrients']?.firstWhere(
                  (nutrient) => nutrient['name'] == 'Fat',
                  orElse: () => {'amount': 0}
                )['amount']?.toString() ?? '0',
              };
            }
          }
        }
      }

      // Se não encontrou dados na API, retorna valores padrão
      return {
        'name': foodName,
        'calories': '0',
        'carbs': '0',
        'protein': '0',
        'fat': '0',
      };
    } catch (e) {
      // Retorna valores padrão em caso de erro
      return {
        'name': foodName,
        'calories': '0',
        'carbs': '0',
        'protein': '0',
        'fat': '0',
      };
    }
  }

  // Método de tradução manual como fallback
  static String _translateToPortugueseManual(String englishName) {
    final translations = {
      'pasta': 'massa',
      'meat': 'carne',
      'basil': 'manjericão',
      'tomato': 'tomate',
      'beef': 'carne bovina',
      'penne': 'penne',
      'cheese': 'queijo',
      'tagliatelle': 'tagliatelle',
      'spaghetti bolognese': 'espaguete à bolonhesa',
      'sausage': 'salsicha',
      'macaroni': 'macarrão',
      'chicken': 'frango',
      'garlic': 'alho',
      'parmesan': 'parmesão',
      'spaghetti carbonara': 'espaguete à carbonara',
      'goulash': 'goulash',
      'ground beef': 'carne moída',
      'garlic bread': 'pão de alho',
      'pork': 'porco',
      'french fries': 'batata frita',
      'apple': 'maçã',
      'banana': 'banana',
      'orange': 'laranja',
      'grape': 'uva',
      'strawberry': 'morango',
      'pineapple': 'abacaxi',
      'watermelon': 'melancia',
      'lemon': 'limão',
      'lime': 'lima',
      'peach': 'pêssego',
      'pear': 'pêra',
      'cherry': 'cereja',
      'mango': 'manga',
      'kiwi': 'kiwi',
      'potato': 'batata',
      'carrot': 'cenoura',
      'onion': 'cebola',
      'pepper': 'pimentão',
      'broccoli': 'brócolis',
      'spinach': 'espinafre',
      'lettuce': 'alface',
      'cabbage': 'repolho',
      'fish': 'peixe',
      'salmon': 'salmão',
      'tuna': 'atum',
      'egg': 'ovo',
      'milk': 'leite',
      'yogurt': 'iogurte',
      'bread': 'pão',
      'rice': 'arroz',
      'cereal': 'cereal',
      'oat': 'aveia',
      'wheat': 'trigo',
      'corn': 'milho',
      'bean': 'feijão',
      'lentil': 'lentilha',
      'chickpea': 'grão de bico',
      'nut': 'nozes',
      'almond': 'amêndoa',
      'walnut': 'noz',
      'peanut': 'amendoim',
      'cashew': 'castanha de caju'
    };

    return translations[englishName.toLowerCase()] ?? englishName;
  }


}
