import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddIngredientDialog extends StatefulWidget {
  final Function(String, String, String) onAddIngredient;
  final List<String> existingIngredients;

  const AddIngredientDialog({
    super.key,
    required this.onAddIngredient,
    required this.existingIngredients,
  });

  @override
  _AddIngredientDialogState createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedUnit = 'un';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onAddIngredient(
        _nameController.text.trim(),
        _quantityController.text.trim(),
        _selectedUnit,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value * (1 - _opacityAnimation.value),
            child: child,
          ),
        );
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Adicionar Ingrediente',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Ingrediente',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fastfood),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome do ingrediente';
                    }
                    if (widget.existingIngredients
                        .any((ing) => ing.toLowerCase() == value.toLowerCase())) {
                      return 'Este ingrediente já foi adicionado';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\,?\d*')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Insira a quantidade';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unidade',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'un',
                            child: Text('un'),
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
                            value: 'L',
                            child: Text('L'),
                          ),
                          DropdownMenuItem(
                            value: 'colher(es)',
                            child: Text('colher(es)'),
                          ),
                          DropdownMenuItem(
                            value: 'xícara(s)',
                            child: Text('xícara(s)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUnit = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCELAR'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('ADICIONAR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showAddIngredientDialog(
  BuildContext context, {
  required Function(String, String, String) onAddIngredient,
  required List<String> existingIngredients,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Adicionar Ingrediente',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AddIngredientDialog(
        onAddIngredient: onAddIngredient,
        existingIngredients: existingIngredients,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        ),
      );
    },
  );
}
