import 'dart:convert';

import 'package:desperdicio_zero/models/barcode_lookup_result.dart';
import 'package:http/http.dart' as http;

class BarcodeLookupService {
  static const String _apiBase = 'https://world.openfoodfacts.org/api/v2/product';

  Future<BarcodeLookupResult?> fetchByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    final uri = Uri.parse('$_apiBase/$cleanBarcode.json');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if ((body['status'] as num?)?.toInt() != 1) {
      return null;
    }

    final product = body['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    final name = (product['product_name_pt'] ??
            product['product_name'] ??
            product['generic_name_pt'] ??
            product['generic_name'])
        ?.toString()
        .trim();
    if (name == null || name.isEmpty) return null;

    final quantityRaw = product['quantity']?.toString();
    final parsedQuantity = _parseQuantity(quantityRaw);
    final parsedUnit = _parseUnit(quantityRaw);

    return BarcodeLookupResult(
      barcode: cleanBarcode,
      productName: name,
      brand: product['brands']?.toString(),
      category: product['categories_tags'] is List && (product['categories_tags'] as List).isNotEmpty
          ? (product['categories_tags'] as List).first.toString().replaceFirst('en:', '')
          : product['categories']?.toString(),
      quantity: parsedQuantity,
      unit: parsedUnit,
    );
  }

  double? _parseQuantity(String? value) {
    if (value == null) return null;
    final match = RegExp(r'(\d+[\\.,]?\d*)').firstMatch(value);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  String? _parseUnit(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase();
    if (lower.contains('kg')) return 'kg';
    if (lower.contains(' g')) return 'g';
    if (lower.contains('ml')) return 'ml';
    if (lower.contains('cl')) return 'ml';
    if (lower.contains(' l')) return 'l';
    return null;
  }
}
