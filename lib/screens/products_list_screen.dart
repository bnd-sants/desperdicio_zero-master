import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat, DateFormat;
import '../models/product_model.dart';
import 'add_product/add_product_screen.dart';
import 'dart:async';

class ProductsListScreen extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onProductTapped;
  final Function(Product) onProductDeleted;

  const ProductsListScreen({
    super.key,
    required this.products,
    required this.onProductTapped,
    required this.onProductDeleted,
  });

  @override
  ProductsListScreenState createState() => ProductsListScreenState();
}

class ProductsListScreenState extends State<ProductsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  List<Product> _filteredProducts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(ProductsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products != oldWidget.products) {
      setState(() {
        _filteredProducts = List.from(widget.products);
        _filterProducts();
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debouncer.run(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterProducts();
      });
    });
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(widget.products);
    } else {
      _filteredProducts = widget.products.where((product) {
        return product.name.toLowerCase().contains(_searchQuery) ||
            (product.type?.toLowerCase().contains(_searchQuery) ?? false) ||
            (product.brand?.toLowerCase().contains(_searchQuery) ?? false) ||
            (product.store?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Produtos'),
        backgroundColor: Colors.green,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar produtos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(currencyFormat, dateFormat),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newProduct = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddProductScreen(onProductAdded: (product) => product),
            ),
          );

          if (newProduct != null) {
            widget.onProductTapped(newProduct);
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(NumberFormat currencyFormat, DateFormat dateFormat) {
    if (widget.products.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_filteredProducts.length} ${_filteredProducts.length == 1 ? 'resultado' : 'resultados'} para "$_searchQuery"',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        Expanded(
          child: _filteredProducts.isEmpty
              ? _buildNoResults()
              : ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(
                            _getIconForProductType(product.type ?? 'outros'),
                            color: Colors.green[800],
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: product.isConsumed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${product.quantity} ${product.unit} • ${currencyFormat.format(product.price)}',
                            ),
                            if (product.expirationDate != null)
                              Text(
                                'Validade: ${dateFormat.format(product.expirationDate!)}',
                                style: TextStyle(
                                  color: _getExpirationColor(
                                    product.expirationDate!,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                product.isConsumed
                                    ? Icons.undo
                                    : Icons.check_circle_outline,
                                color: product.isConsumed
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                              onPressed: () => widget.onProductTapped(product),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => widget.onProductDeleted(product),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showProductDetails(
                            context,
                            product,
                            currencyFormat,
                            dateFormat,
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Nenhum produto adicionado',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque no botão + para adicionar um produto',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Nenhum produto encontrado',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhum resultado para "$_searchQuery"',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  IconData _getIconForProductType(String type) {
    switch (type.toLowerCase()) {
      case 'alimento':
        return Icons.fastfood;
      case 'bebida':
        return Icons.local_drink;
      case 'limpeza':
        return Icons.cleaning_services;
      case 'higiene':
        return Icons.soap;
      default:
        return Icons.shopping_bag;
    }
  }

  Color _getExpirationColor(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;

    if (expirationDate.isBefore(now)) {
      return Colors.red; // Vencido
    } else if (difference <= 3) {
      return Colors.orange; // Vencendo em breve
    } else {
      return Colors.green; // Dentro do prazo
    }
  }

  void _showProductDetails(
    BuildContext context,
    Product product,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  _getIconForProductType(product.type ?? 'outros'),
                  size: 32,
                  color: Colors.green[800],
                ),
                const SizedBox(width: 16),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Tipo', product.type ?? 'Não especificado'),
            _buildDetailRow(
              'Quantidade',
              '${product.quantity} ${product.unit}',
            ),
            _buildDetailRow('Preço', currencyFormat.format(product.price)),
            if (product.brand != null) _buildDetailRow('Marca', product.brand!),
            if (product.store != null)
              _buildDetailRow('Mercado', product.store!),
            _buildDetailRow(
              'Data da Compra',
              product.purchaseDate != null 
                  ? dateFormat.format(product.purchaseDate!)
                  : 'Não informada',
            ),
            if (product.expirationDate != null)
              _buildDetailRow(
                'Data de Validade',
                dateFormat.format(product.expirationDate!),
                textColor: _getExpirationColor(product.expirationDate!),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Classe auxiliar para debounce da pesquisa
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
