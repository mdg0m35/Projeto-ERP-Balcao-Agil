import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/dialogs/quantity_dialog.dart';
import '../../widgets/modals/cart_modal.dart';

class PosTab extends StatefulWidget {
  const PosTab({super.key});
  @override
  State<PosTab> createState() => _PosTabState();
}

class _PosTabState extends State<PosTab> {
  String _search = '';

  void _openEditProductStockDialog(Product p) {
    final stockCtrl = TextEditingController(text: p.stock.toString());
    final priceCtrl = TextEditingController(text: p.price.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Estoque / Preço: ${p.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Estoque Atual (${p.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Preço de Venda (R\$)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(stockCtrl.text.trim()) ?? p.stock;
              final newPrice =
                  double.tryParse(priceCtrl.text.replaceAll(',', '.')) ??
                      p.price;
              p.stock = newStock;
              p.price = newPrice;
              context.read<AppProvider>().updateProduct(p);
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final primaryColor = provider.primaryColor;
    final isOwner = provider.isOwner;

    final filtered = provider.products.where((p) {
      return p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.category.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar produto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Nenhum produto encontrado.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        final isOutOfStock = p.stock <= 0;
                        final isLowStock = p.stock > 0 && p.stock <= 10;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isOutOfStock
                                  ? Colors.red.shade200
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      primaryColor.withOpacity(0.1),
                                  child: Icon(p.iconData, color: primaryColor),
                                ),
                                PositionedDirectional(
                                  bottom: 0,
                                  end: 0,
                                  child: CircleAvatar(
                                    radius: 5,
                                    backgroundColor: isOutOfStock
                                        ? Colors.red
                                        : (isLowStock
                                            ? Colors.orange
                                            : Colors.green),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? Colors.red[50]
                                        : (isLowStock
                                            ? Colors.orange[50]
                                            : Colors.green[50]),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isOutOfStock
                                        ? 'Esgotado'
                                        : (isLowStock
                                            ? 'Baixo Estoque'
                                            : 'Em Estoque'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOutOfStock
                                          ? Colors.red[800]
                                          : (isLowStock
                                              ? Colors.orange[900]
                                              : Colors.green[800]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Estoque: ${p.stock} ${p.unit} • Categoria: ${p.category}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'R\$ ${p.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isOwner)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_note,
                                      color: Colors.blueGrey,
                                    ),
                                    tooltip: 'Alterar Estoque / Preço (Admin)',
                                    onPressed: () =>
                                        _openEditProductStockDialog(p),
                                  ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: isOutOfStock
                                        ? Colors.grey
                                        : primaryColor,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          QuantityDialog(product: p),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: provider.cart.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                'Orçamento (${provider.totalItemsCount}) • R\$ ${provider.totalBudget.toStringAsFixed(2)}',
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const CartModal(),
                );
              },
            )
          : null,
    );
  }
}
