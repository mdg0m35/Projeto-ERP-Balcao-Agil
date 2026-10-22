import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';

class SuppliersTab extends StatefulWidget {
  const SuppliersTab({super.key});

  @override
  State<SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends State<SuppliersTab> {
  String _search = '';
  String _filter = 'Todos';

  void _openOrderDialog({SupplierOrder? existingOrder}) {
    final nameCtrl =
        TextEditingController(text: existingOrder?.supplierName ?? '');
    final phoneCtrl =
        TextEditingController(text: existingOrder?.supplierPhone ?? '');
    final descCtrl =
        TextEditingController(text: existingOrder?.description ?? '');
    final totalCtrl = TextEditingController(
        text: existingOrder?.totalAmount.toStringAsFixed(2) ?? '');
    final paidCtrl = TextEditingController(
        text: existingOrder?.paidAmount.toStringAsFixed(2) ?? '0');
    final salesCtrl = TextEditingController(
      text: (existingOrder?.expectedSalesAmount ?? 0) > 0
          ? existingOrder!.expectedSalesAmount.toStringAsFixed(2)
          : '',
    );
    final notesCtrl = TextEditingController(text: existingOrder?.notes ?? '');

    String deliveryStatus =
        existingOrder?.deliveryStatus ?? 'Aguardando Entrega';
    String paymentStatus = existingOrder?.paymentStatus ?? 'Pendente';
    DateTime selectedDate = existingOrder?.expectedDeliveryDate ??
        DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          final costVal =
              double.tryParse(totalCtrl.text.replaceAll(',', '.')) ?? 0;
          final saleVal =
              double.tryParse(salesCtrl.text.replaceAll(',', '.')) ?? 0;
          final profit = saleVal - costVal;

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.fire_truck_rounded, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(existingOrder == null
                    ? 'Nova Compra com Fornecedor'
                    : 'Editar Pedido'),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Fornecedor / Empresa',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp / Telefone do Fornecedor',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descrição dos Materiais Comprados',
                        hintText:
                            'Ex: 2 Carradas de Tijolos 8 furos (6.000 un)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: totalCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Custo Total Compra (R\$)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: paidCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Valor Pago Agora (R\$)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: salesCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Previsão de Venda Total do Lote (R\$)',
                        hintText:
                            'Ex: Se comprou por 5000 e vai vender tudo a 8000',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (costVal > 0 && saleVal > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              profit >= 0 ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: profit >= 0
                                  ? Colors.green.shade200
                                  : Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              profit >= 0
                                  ? 'Lucro Bruto Projetado:'
                                  : 'Prejuízo Projetado:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: profit >= 0
                                    ? Colors.green[900]
                                    : Colors.red[900],
                              ),
                            ),
                            Text(
                              'R\$ ${profit.toStringAsFixed(2)} (${saleVal > 0 ? ((profit / saleVal) * 100).toStringAsFixed(1) : 0}%)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: profit >= 0
                                    ? Colors.green[900]
                                    : Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: deliveryStatus,
                            decoration: const InputDecoration(
                                labelText: 'Status Entrega',
                                border: OutlineInputBorder(),
                                isDense: true),
                            items: [
                              'Aguardando Entrega',
                              'Recebido Parcial',
                              'Entregue'
                            ].map((s) {
                              return DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (v) =>
                                setDState(() => deliveryStatus = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: paymentStatus,
                            decoration: const InputDecoration(
                                labelText: 'Pagamento',
                                border: OutlineInputBorder(),
                                isDense: true),
                            items: ['Pendente', 'Parcial', 'Pago'].map((s) {
                              return DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (v) =>
                                setDState(() => paymentStatus = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                          'Previsão de Chegada: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 30)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setDState(() => selectedDate = d);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observações (Boleto, Freteiro, NF)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final total =
                      double.tryParse(totalCtrl.text.replaceAll(',', '.')) ?? 0;
                  final paid =
                      double.tryParse(paidCtrl.text.replaceAll(',', '.')) ?? 0;
                  final sales =
                      double.tryParse(salesCtrl.text.replaceAll(',', '.')) ?? 0;

                  if (nameCtrl.text.trim().isEmpty ||
                      descCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Preencha fornecedor e descrição do material.'),
                          backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  final provider = context.read<AppProvider>();
                  if (existingOrder == null) {
                    provider.addSupplierOrder(
                      SupplierOrder(
                        id: '',
                        storeId: provider.storeId,
                        supplierName: nameCtrl.text.trim(),
                        supplierPhone: phoneCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        totalAmount: total,
                        paidAmount: paid,
                        expectedSalesAmount: sales,
                        deliveryStatus: deliveryStatus,
                        paymentStatus: paymentStatus,
                        expectedDeliveryDate: selectedDate,
                        notes: notesCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      ),
                    );
                  } else {
                    existingOrder.supplierName = nameCtrl.text.trim();
                    existingOrder.supplierPhone = phoneCtrl.text.trim();
                    existingOrder.description = descCtrl.text.trim();
                    existingOrder.totalAmount = total;
                    existingOrder.paidAmount = paid;
                    existingOrder.expectedSalesAmount = sales;
                    existingOrder.deliveryStatus = deliveryStatus;
                    existingOrder.paymentStatus = paymentStatus;
                    existingOrder.expectedDeliveryDate = selectedDate;
                    existingOrder.notes = notesCtrl.text.trim();
                    provider.updateSupplierOrder(existingOrder);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Salvar Pedido'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final primaryColor = provider.primaryColor;

    final filtered = provider.supplierOrders.where((o) {
      final matchesSearch =
          o.supplierName.toLowerCase().contains(_search.toLowerCase()) ||
              o.description.toLowerCase().contains(_search.toLowerCase());
      if (!matchesSearch) return false;
      if (_filter == 'Aguardando')
        return o.deliveryStatus == 'Aguardando Entrega';
      if (_filter == 'A Pagar') return o.remainingBalance > 0;
      if (_filter == 'Entregues') return o.deliveryStatus == 'Entregue';
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Pesquisar compras, fornecedor ou material...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Comprar de Fornecedor'),
                onPressed: () => _openOrderDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Todos', 'Aguardando', 'A Pagar', 'Entregues'].map((f) {
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
                ? const Center(
                    child: Text('Nenhum pedido de compra registrado.'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final o = filtered[i];
                      final isPending =
                          o.deliveryStatus == 'Aguardando Entrega';
                      final hasDebt = o.remainingBalance > 0;
                      final hasSalesEstimation = o.expectedSalesAmount > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: isPending
                                ? Colors.orange[50]
                                : Colors.green[50],
                            child: Icon(
                              isPending ? Icons.local_shipping : Icons.verified,
                              color: isPending ? Colors.orange : Colors.green,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(o.supplierName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? Colors.orange[50]
                                      : Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  o.deliveryStatus,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPending
                                        ? Colors.orange[900]
                                        : Colors.green[800],
                                  ),
                                ),
                              ),
                              if (hasDebt) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                      'Falta R\$ ${o.remainingBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Material: ${o.description}'),
                              Row(
                                children: [
                                  Text(
                                    'Custo: R\$ ${o.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12),
                                  ),
                                  if (hasSalesEstimation) ...[
                                    const Text(' • ',
                                        style: TextStyle(color: Colors.grey)),
                                    Text(
                                      'Lucro Previsto: +R\$ ${o.projectedProfit.toStringAsFixed(2)} (${o.profitMarginPercent.toStringAsFixed(1)}%)',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Contato: ${o.supplierPhone.isNotEmpty ? o.supplierPhone : "Não informado"}'),
                                  if (hasSalesEstimation)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Text(
                                        'Revenda Total Prevista: R\$ ${o.expectedSalesAmount.toStringAsFixed(2)} (Lucro Bruto: R\$ ${o.projectedProfit.toStringAsFixed(2)})',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800]),
                                      ),
                                    ),
                                  if (o.notes != null && o.notes!.isNotEmpty)
                                    Text('Observações: ${o.notes}'),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red, size: 18),
                                        label: const Text('Excluir',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onPressed: () =>
                                            provider.deleteSupplierOrder(o.id),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Editar / Pagamento'),
                                        onPressed: () =>
                                            _openOrderDialog(existingOrder: o),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
