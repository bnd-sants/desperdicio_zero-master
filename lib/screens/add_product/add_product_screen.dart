import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:desperdicio_zero/utils/logger_util.dart'
    show logInfo, logDebug, logError;
import 'package:desperdicio_zero/services/notification_service.dart';
import 'package:desperdicio_zero/widgets/app_snackbar.dart';
import 'package:desperdicio_zero/widgets/app_button.dart';
import 'package:desperdicio_zero/widgets/app_text_field.dart';
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';

import '../../../models/product_model.dart';
import '../../../services/food_recognition_service.dart';
import 'package:desperdicio_zero/core/providers/index.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:desperdicio_zero/services/ocr_service.dart';
import 'package:desperdicio_zero/core/providers/gamification_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Function(Product)? onProductAdded;
  final Product? productToEdit;

  const AddProductScreen({super.key, this.onProductAdded, this.productToEdit});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  // Form field controllers
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _storeController = TextEditingController();
  final _priceController = TextEditingController();

  // Nutritional information controllers
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  // Form state
  String _selectedUnit = 'un';
  DateTime _purchaseDate = DateTime.now();
  DateTime? _expirationDate;
  bool _isLoading = false;

  // Get the current user ID from the auth provider
  String get _userId {
    final authState = ref.watch(authNotifierProvider);
    return authState.maybeWhen(
      authenticated: (profile) => profile.id,
      orElse: () => '',
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _storeController.dispose();
    _priceController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.productToEdit != null) {
      final product = widget.productToEdit!;
      _nameController.text = product.name;
      _typeController.text = product.type ?? '';
      _brandController.text = product.brand ?? '';
      _quantityController.text = product.quantity.toString();
      _selectedUnit = product.unit;
      _purchaseDate = product.purchaseDate ?? DateTime.now();
      _expirationDate = product.expirationDate;
      _storeController.text = product.store ?? '';
      final price = product.price ?? 0.0;
      _priceController.text = price > 0 ? price.toStringAsFixed(2) : '';

      // Initialize nutritional fields
      _caloriesController.text = product.calories?.toString() ?? '';
      _carbsController.text = product.carbs?.toString() ?? '';
      _proteinController.text = product.protein?.toString() ?? '';
      _fatController.text = product.fat?.toString() ?? '';
    }
  }

  Future<void> _recognizeFood() async {
    try {
      // Mostra um indicador de carregamento
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Captura a imagem
      final imageFile = await FoodRecognitionService.captureImage();
      if (!mounted) return;

      if (imageFile == null) {
        Navigator.pop(context); // Remove o diálogo de carregamento
        return;
      }

      // Reconhece o alimento
      final foodData = await FoodRecognitionService.recognizeFood(imageFile);
      // Remove o diálogo de carregamento
      if (!mounted) return;
      Navigator.pop(context);

      if (foodData != null) {
        // Preenche os campos com as informações reconhecidas
        setState(() {
          _nameController.text = foodData['name'] ?? '';
          _caloriesController.text = foodData['calories'] ?? '0';
          _carbsController.text = foodData['carbs'] ?? '0';
          _proteinController.text = foodData['protein'] ?? '0';
          _fatController.text = foodData['fat'] ?? '0';
          // Define uma data de validade padrão (7 dias a partir de hoje)
          _expirationDate = DateTime.now().add(const Duration(days: 7));
        });

        // Mostra um SnackBar de sucesso
        if (mounted) {
          AppSnackbar.showSuccess(
            context: context,
            message: 'Alimento reconhecido: ${foodData['name'] ?? ''}',
          );
        }
      } else {
        // Se não conseguiu reconhecer, mostra uma mensagem
        if (mounted) {
          AppSnackbar.showWarning(
            context: context,
            message: 'Não foi possível reconhecer o alimento. Tente novamente.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(
          context,
        ); // Remove o diálogo de carregamento em caso de erro
        AppSnackbar.showError(
          context: context,
          message: 'Erro ao processar a imagem: $e',
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final product = Product(
        id: widget.productToEdit?.id ?? _uuid.v4(),
        name: _nameController.text.trim(),
        type: _typeController.text.trim().isNotEmpty
            ? _typeController.text.trim()
            : null,
        brand: _brandController.text.trim().isNotEmpty
            ? _brandController.text.trim()
            : null,
        quantity: double.tryParse(_quantityController.text) ?? 1.0,
        unit: _selectedUnit,
        purchaseDate: _purchaseDate,
        expirationDate: _expirationDate,
        store: _storeController.text.trim().isNotEmpty
            ? _storeController.text.trim()
            : null,
        price: _priceController.text.trim().isNotEmpty
            ? double.tryParse(_priceController.text) ?? 0.0
            : null,
        userId: _userId,
        createdAt: widget.productToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        calories: _caloriesController.text.trim().isNotEmpty
            ? int.tryParse(_caloriesController.text.trim())
            : null,
        carbs: _carbsController.text.trim().isNotEmpty
            ? double.tryParse(_carbsController.text.trim())
            : null,
        protein: _proteinController.text.trim().isNotEmpty
            ? double.tryParse(_proteinController.text.trim())
            : null,
        fat: _fatController.text.trim().isNotEmpty
            ? double.tryParse(_fatController.text.trim())
            : null,
      );

      final productsNotifier = ref.read(productsProvider.notifier);

      if (widget.productToEdit != null) {
        await productsNotifier.updateProduct(product);
        if (mounted) {
          AppSnackbar.showSuccess(
            context: context,
            message: 'Produto atualizado com sucesso!',
          );
        }
      } else {
        await productsNotifier.addProduct(product);
        if (mounted) {
          AppSnackbar.showSuccess(
            context: context,
            message: 'Produto adicionado com sucesso!',
          );
        }
        // Notifica o provedor de gamificação sobre o novo produto
        ref.read(gamificationProvider.notifier).onProductAdded();
      }

      // Força a atualização da lista de produtos
      await productsNotifier.refresh();

      // Agenda notificações para o produto
      if (product.expirationDate != null) {
        try {
          final notificationService = NotificationService.instance;
          final now = DateTime.now();
          final expirationDate = product.expirationDate!;
          // Se a data de validade for futura, agenda as notificações
          if (expirationDate.isAfter(now)) {
            await notificationService.scheduleStandardProductNotifications(
              ref: ref,
              product: product,
            );

            logInfo('Notificações agendadas para o produto ${product.name}');
          }
        } catch (e) {
          logError('Erro ao agendar notificações', e);
          if (mounted) {
            AppSnackbar.showWarning(
              context: context,
              message:
                  'Produto salvo, mas houve um erro ao agendar notificações.',
            );
          }
        }
      }

      if (mounted) {
        logInfo('Produto salvo com sucesso!');
        Navigator.of(context).pop(true);
        logDebug('Chamando callback onProductAdded...');
        widget.onProductAdded?.call(product);
        logDebug('Callback executado');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Erro ao salvar produto: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (widget.productToEdit == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tem certeza que deseja excluir este produto?'),
            const SizedBox(height: 16),
            const Text('Como este produto será descartado?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              // Notifica o provedor de gamificação sobre o descarte
              ref.read(gamificationProvider.notifier).onProductDiscarded();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(productsProvider.notifier)
          .removeProduct(widget.productToEdit!.id);

      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackbar.showSuccess(
          context: context,
          message: 'Produto excluído com sucesso!',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Erro ao excluir produto: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addByPhotoOCR() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.camera);
      if (xfile == null) {
        setState(() => _isLoading = false);
        return;
      }
      final file = File(xfile.path);
      final products = await OcrService.instance.recognizeProductsFromImage(
        file,
      );
      setState(() => _isLoading = false);
      if (products.isEmpty) {
        if (mounted) {
          AppSnackbar.showWarning(
            context: context,
            message: 'Nenhum produto reconhecido.',
          );
        }
        return;
      }
      // Exibir pré-visualização e pedir confirmação (stub simples)
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Produtos Reconhecidos'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...products.map(
                  (e) => ListTile(
                    title: Text(e.name),
                    subtitle: Text(
                      'Qtd: ${e.quantity ?? '-'} ${e.unit ?? ''} Validade: ${e.expirationDate?.toString().substring(0, 10) ?? '-'}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Cadastrar Todos'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        final productsNotifier = ref.read(productsProvider.notifier);
        for (final p in products) {
          await productsNotifier.addProduct(
            Product(
              id: _uuid.v4(),
              userId: _userId,
              name: p.name,
              quantity: p.quantity ?? 1,
              unit: p.unit ?? 'un',
              expirationDate: p.expirationDate,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isConsumed: false,
              brand: null,
              store: null,
              price: null,
              purchaseDate: null,
              calories: null,
              carbs: null,
              protein: null,
              fat: null,
              type: null,
            ),
          );
        }
        if (mounted) {
          AppSnackbar.showSuccess(
            context: context,
            message: 'Produtos cadastrados!',
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Erro ao processar OCR: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productToEdit != null ? 'Editar Produto' : 'Adicionar Produto',
        ),
        actions: [
          if (widget.productToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteProduct,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(StyleTokens.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'Nome do produto',
                            prefixIcon: const Icon(Icons.shopping_bag_outlined),
                            isRequired: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, insira o nome do produto';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: StyleTokens.spacingL),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppTextField(
                                  controller: _quantityController,
                                  label: 'Quantidade',
                                  prefixIcon: const Icon(Icons.numbers),
                                  keyboardType: TextInputType.number,
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe a quantidade';
                                    }
                                    if (double.tryParse(
                                          value.replaceAll(',', '.'),
                                        ) ==
                                        null) {
                                      return 'Número inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: StyleTokens.spacingM),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedUnit,
                                  decoration: InputDecoration(
                                    labelText: 'Unidade',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: StyleTokens.spacingM,
                                      vertical: StyleTokens.spacingS,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        StyleTokens.radiusM,
                                      ),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'un',
                                      child: Text('Un'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'g',
                                      child: Text('g'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'kg',
                                      child: Text('kg'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ml',
                                      child: Text('ml'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'l',
                                      child: Text('L'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedUnit = value);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Selecione a unidade';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: StyleTokens.spacingL),
                          AppTextField(
                            controller: _brandController,
                            label: 'Marca (opcional)',
                            prefixIcon: const Icon(
                              Icons.branding_watermark_outlined,
                            ),
                          ),
                          const SizedBox(height: StyleTokens.spacingL),
                          AppTextField(
                            controller: _typeController,
                            label: 'Tipo (opcional)',
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          const SizedBox(height: StyleTokens.spacingL),
                          AppTextField(
                            controller: _storeController,
                            label: 'Loja (opcional)',
                            prefixIcon: const Icon(
                              Icons.store_mall_directory_outlined,
                            ),
                          ),
                          const SizedBox(height: StyleTokens.spacingL),
                          AppTextField(
                            controller: _priceController,
                            label: 'Preço (opcional)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingXL),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: StyleTokens.spacingS),
                              Text(
                                'Datas importantes',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: StyleTokens.spacingM),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.shopping_cart_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: const Text('Data de compra'),
                            subtitle: Text(
                              '${_purchaseDate.day.toString().padLeft(2, '0')}/${_purchaseDate.month.toString().padLeft(2, '0')}/${_purchaseDate.year}',
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.edit_calendar,
                                color: colorScheme.primary,
                              ),
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _purchaseDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null && picked != _purchaseDate) {
                                  setState(() {
                                    _purchaseDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.event_available_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: const Text('Data de validade (opcional)'),
                            subtitle: Text(
                              _expirationDate != null
                                  ? '${_expirationDate!.day.toString().padLeft(2, '0')}/${_expirationDate!.month.toString().padLeft(2, '0')}/${_expirationDate!.year}'
                                  : 'Não definida',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_expirationDate != null)
                                  IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: colorScheme.error,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _expirationDate = null;
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_calendar,
                                    color: colorScheme.primary,
                                  ),
                                  onPressed: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _expirationDate ??
                                              DateTime.now().add(
                                                const Duration(days: 7),
                                              ),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2100),
                                        );
                                    if (picked != null) {
                                      setState(() {
                                        _expirationDate = picked;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: StyleTokens.spacingS),
                        Expanded(
                          child: Text(
                            'Informações nutricionais são opcionais. Use os valores do rótulo ou deixe em branco caso não saiba.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: StyleTokens.spacingM),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant_menu_outlined,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: StyleTokens.spacingS),
                              Text(
                                'Informações nutricionais',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: StyleTokens.spacingL),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _caloriesController,
                                  label: 'Calorias (kcal)',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(
                                    Icons.local_fire_department_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(width: StyleTokens.spacingM),
                              Expanded(
                                child: AppTextField(
                                  controller: _carbsController,
                                  label: 'Carboidratos (g)',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.grain),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: StyleTokens.spacingL),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _proteinController,
                                  label: 'Proteínas (g)',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.fitness_center),
                                ),
                              ),
                              const SizedBox(width: StyleTokens.spacingM),
                              Expanded(
                                child: AppTextField(
                                  controller: _fatController,
                                  label: 'Gorduras (g)',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.opacity),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingXL),
                    AppButton(
                      text: widget.productToEdit != null
                          ? 'Atualizar produto'
                          : 'Adicionar produto',
                      onPressed: () {
                        if (_isLoading) return;
                        _saveProduct();
                      },
                      isLoading: _isLoading,
                      borderRadius: StyleTokens.radiusM,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _recognizeFood,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: StyleTokens.spacingM,
                        ),
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            StyleTokens.radiusM,
                          ),
                        ),
                      ),
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: _isLoading
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary,
                      ),
                      label: Text(
                        'Reconhecer com câmera',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _isLoading
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _addByPhotoOCR,
                      icon: Icon(
                        Icons.photo_camera_back_outlined,
                        color: _isLoading
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.secondary,
                      ),
                      label: Text(
                        'Adicionar via Foto/OCR',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _isLoading
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.productToEdit != null) ...[
                      const SizedBox(height: StyleTokens.spacingL),
                      Text(
                        'Criado em: ${widget.productToEdit!.createdAt.toString().substring(0, 10)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
