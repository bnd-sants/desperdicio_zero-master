import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrProductCandidate {
  final String name;
  final int? quantity;
  final String? unit;
  final DateTime? expirationDate;

  OcrProductCandidate({
    required this.name,
    this.quantity,
    this.unit,
    this.expirationDate,
  });
}

class OcrService {
  static final instance = OcrService();
  OcrService();

  Future<List<OcrProductCandidate>> recognizeProductsFromImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    final List<OcrProductCandidate> results = [];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final extracted = _extractFieldsFromLine(line.text);
        if (extracted != null) {
          results.add(extracted);
        }
      }
    }
    return results;
  }

  /// Regex para tentar extrair nome, quantidade e unidade da linha
  OcrProductCandidate? _extractFieldsFromLine(String line) {
    final regex = RegExp(r'([\w\sáéíóúãõâêîôûç]+)\s*(\d+)?\s*([gkmlunL]*)', caseSensitive: false);
    final match = regex.firstMatch(line);
    if (match != null && match.group(1)?.trim().isNotEmpty == true) {
      final nome = match.group(1)?.trim() ?? '';
      final qtdeRaw = match.group(2);
      final unidadeRaw = match.group(3);
      int? quantidade = qtdeRaw != null ? int.tryParse(qtdeRaw) : null;
      String? unidade = unidadeRaw != null && unidadeRaw.isNotEmpty ? unidadeRaw : null;
      return OcrProductCandidate(name: nome, quantity: quantidade, unit: unidade);
    }
    // Fallback: Se linha tem texto, retorna só nome
    if (line.trim().isNotEmpty) {
      return OcrProductCandidate(name: line.trim());
    }
    return null;
  }
}
