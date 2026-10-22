import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';

class StockTab extends StatefulWidget {
  const StockTab({super.key});
  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab> {
  String _filter = 'Todos';

  void _openStockEditor(Product p) {
    final stockCtrl = TextEditingController(text: p.stock.toString());
    final priceCtrl = TextEditingController(text: p.price.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Repor Estoque: ${p.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Quantidade em Estoque (${p.unit})',
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Preço de Venda (R\$)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
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
            child: const Text('Salvar Alterações'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final primaryColor = provider.primaryColor;

    final filtered = provider.products.where((p) {
      if (_filter == 'Zerados') return p.stock <= 0;
      if (_filter == 'Baixo Estoque') return p.stock > 0 && p.stock <= 10;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['Todos', 'Baixo Estoque', 'Zerados'].map((f) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (sel) =>
                      setState(() => _filter = sel ? f : 'Todos'),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Nenhum produto neste filtro.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final isOutOfStock = p.stock <= 0;
                      final isLowStock = p.stock > 0 && p.stock <= 10;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: isOutOfStock
                                  ? Colors.red.shade200
                                  : const Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isOutOfStock
                                ? Colors.red[50]
                                : (isLowStock
                                    ? Colors.orange[50]
                                    : Colors.green[50]),
                            child: Icon(
                              isOutOfStock
                                  ? Icons.warning_amber_rounded
                                  : Icons.inventory_2_outlined,
                              color: isOutOfStock
                                  ? Colors.red
                                  : (isLowStock ? Colors.orange : Colors.green),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: isOutOfStock
                                    ? Colors.red
                                    : (isLowStock
                                        ? Colors.orange
                                        : Colors.green),
                              ),
                            ],
                          ),
                          subtitle: Text(
                              'Estoque Atual: ${p.stock} ${p.unit} • Preço: R\$ ${p.price.toStringAsFixed(2)}'),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Repor Estoque'),
                            onPressed: () => _openStockEditor(p),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
