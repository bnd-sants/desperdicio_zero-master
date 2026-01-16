import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/shopping_list_provider.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingList = ref.watch(shoppingListProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Compras')),
      body: shoppingList.isEmpty
          ? Center(child: Text('Nenhum item na lista!'))
          : ListView.builder(
              itemCount: shoppingList.length,
              itemBuilder: (context, index) {
                final item = shoppingList[index];
                return Card(
                  color: item.status == ShoppingListItemStatus.suggested
                    ? Colors.yellow[50]
                    : null,
                  child: ListTile(
                    leading: Checkbox(
                      value: item.status == ShoppingListItemStatus.bought,
                      onChanged: (v) {
                        if (v == true) {
                          ref.read(shoppingListProvider.notifier).markAsBought(item.id);
                        }
                      },
                    ),
                    title: Text(item.name,
                        style: TextStyle(
                          decoration: item.status == ShoppingListItemStatus.bought
                              ? TextDecoration.lineThrough
                              : null,
                        )),
                    subtitle: Text('Qtd: ${item.quantity} ${item.unit}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline),
                      onPressed: () {
                        ref.read(shoppingListProvider.notifier).removeItem(item.id);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add',
            icon: Icon(Icons.add),
            label: Text('Adicionar'),
            onPressed: () async {
              final nameController = TextEditingController();
              final qtyController = TextEditingController();
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Adicionar item à lista'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nome')), 
                      TextField(controller: qtyController, decoration: InputDecoration(labelText: 'Quantidade'), keyboardType: TextInputType.number),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if(nameController.text.isNotEmpty && int.tryParse(qtyController.text) != null) {
                          Navigator.pop(context, {
                            'name': nameController.text,
                            'qty': int.parse(qtyController.text)
                          });
                        }
                      },
                      child: Text('Adicionar'),
                    ),
                  ],
                ),
              );
              if (result != null) {
                ref.read(shoppingListProvider.notifier).addItem(
                  ShoppingListItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: result['name'],
                    quantity: result['qty'],
                    unit: '',
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'clear',
            icon: Icon(Icons.remove_done_outlined),
            label: Text('Limpar comprados'),
            backgroundColor: Colors.red[200],
            onPressed: () {
              ref.read(shoppingListProvider.notifier).clearBought();
            },
          ),
        ],
      ),
    );
  }
}
