class BarcodeLookupResult {
  final String barcode;
  final String productName;
  final String? brand;
  final String? category;
  final double? quantity;
  final String? unit;

  const BarcodeLookupResult({
    required this.barcode,
    required this.productName,
    this.brand,
    this.category,
    this.quantity,
    this.unit,
  });
}
