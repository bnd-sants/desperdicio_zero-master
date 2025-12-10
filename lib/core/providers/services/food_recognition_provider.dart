import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/services/food_recognition_service.dart';

final foodRecognitionServiceProvider = Provider<FoodRecognitionService>((ref) {
  return FoodRecognitionService();
});
