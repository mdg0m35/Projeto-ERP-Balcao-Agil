import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';

class QuantityDialog extends StatefulWidget {
  final Product product;
  const QuantityDialog({super.key, required this.product});

  @override
  State<QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<QuantityDialog> {
  final _qtyCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.stock <= 0) {
      _qty = 0;
      _qtyCtrl.text = '0';
    }
  }

  void _updateQty(int val) {
    if (widget.product.stock <= 0) return;
    setState(() {
      _qty = val.clamp(1, widget.product.stock);
      _qtyCtrl.text = _qty.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.watch<AppProvider>().primaryColor;
    final isOutOfStock = widget.product.stock <= 0;
    final isLowStock = widget.product.stock > 0 && widget.product.stock <= 10;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.product.iconData, color: primaryColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.red[50]
                        : (isLowStock ? Colors.orange[50] : Colors.green[50]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOutOfStock
                          ? Colors.red
                          : (isLowStock ? Colors.orange : Colors.green),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: isOutOfStock
                            ? Colors.red
                            : (isLowStock ? Colors.orange : Colors.green),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOutOfStock
                            ? 'Esgotado (0)'
                            : (isLowStock
                                ? 'Baixo (${widget.product.stock})'
                                : 'OK (${widget.product.stock})'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock
                              ? Colors.red[800]
                              : (isLowStock
                                  ? Colors.orange[900]
                                  : Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Preço: R\$ ${widget.product.price.toStringAsFixed(2)} / ${widget.product.unit}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (isOutOfStock)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Produto com estoque zerado! Não é possível adicionar ao pedido.',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantidade (${widget.product.unit})',
                  border: const OutlineInputBorder(),
                  suffixText: widget.product.unit,
                ),
                onChanged: (v) {
                  final parsed = int.tryParse(v) ?? 1;
                  if (parsed > widget.product.stock) {
                    _updateQty(widget.product.stock);
                  } else {
                    setState(
                        () => _qty = parsed.clamp(1, widget.product.stock));
                  }
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [5, 10, 50, 100]
                    .where((n) => n <= widget.product.stock)
                    .map((n) {
                  return ActionChip(
                    label: Text('+$n'),
                    onPressed: () =>
                        _updateQty((_qty + n).clamp(1, widget.product.stock)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observação do item (opcional)',
                  hintText: 'Ex: Entregar com proteção, cortar...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOutOfStock ? Colors.grey[100] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'R\$ ${(widget.product.price * (isOutOfStock ? 0 : _qty)).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock ? Colors.grey : Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Adicionar'),
                  onPressed: isOutOfStock
                      ? null
                      : () {
                          context.read<AppProvider>().addToCart(
                                widget.product,
                                _qty,
                                note: _noteCtrl.text.trim().isNotEmpty
                                    ? _noteCtrl.text.trim()
                                    : null,
                              );
                          Navigator.pop(context);
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
