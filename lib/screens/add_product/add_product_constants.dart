import 'package:flutter/material.dart';

class AddProductConstants {
  // Paddings
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const double formSpacing = 16.0;
  
  // Border Radius
  static const double borderRadius = 12.0;
  
  // Text Styles
  static TextStyle get titleStyle => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );
      
  static TextStyle get sectionTitleStyle => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );
      
  // Button Texts
  static const String saveButton = 'Salvar';
  static const String cancelButton = 'Cancelar';
  static const String productInfo = 'Informações do Produto';
  static const String purchaseInfo = 'Informações de Compra';
  static const String additionalInfo = 'Informações Adicionais';
  
  // Form Field Labels
  static const String nameLabel = 'Nome do Produto';
  static const String typeLabel = 'Tipo';
  static const String quantityLabel = 'Quantidade';
  static const String unitLabel = 'Unidade';
  static const String purchaseDateLabel = 'Data de Compra';
  static const String expirationDateLabel = 'Data de Validade';
  static const String brandLabel = 'Marca';
  static const String storeLabel = 'Local de Compra';
  static const String priceLabel = 'Preço (opcional)';
  
  // Hints
  static const String nameHint = 'Ex: Arroz Integral';
  static const String typeHint = 'Selecione o tipo';
  static const String quantityHint = '0';
  static const String brandHint = 'Ex: Tio João';
  static const String storeHint = 'Ex: Supermercado X';
  static const String priceHint = '0.00';
  
  // Validation Messages
  static const String nameRequired = 'Por favor, insira o nome do produto';
  static const String quantityRequired = 'Por favor, insira a quantidade';
  static const String quantityInvalid = 'Por favor, insira uma quantidade válida';
  
  // Units
  static const List<String> units = ['g', 'kg', 'ml', 'L', 'un'];
  
  // Product Types
  static const List<String> productTypes = [
    'Alimento',
    'Bebida', 
    'Limpeza',
    'Higiene',
    'Outros',
  ];
  
  // Date Format
  static const String dateFormat = 'dd/MM/yyyy';
  
  // Icons
  static const IconData calendarIcon = Icons.calendar_today;
  static const IconData saveIcon = Icons.save;
  static const IconData cancelIcon = Icons.cancel;
  static const IconData productIcon = Icons.shopping_bag;
  static const IconData infoIcon = Icons.info_outline;
  static const IconData storeIcon = Icons.store;
  static const IconData priceIcon = Icons.attach_money;
}

// Extension for String to provide easy access to the constants
extension AddProductContext on BuildContext {
  AddProductConstants get addProductConstants => AddProductConstants();
}
