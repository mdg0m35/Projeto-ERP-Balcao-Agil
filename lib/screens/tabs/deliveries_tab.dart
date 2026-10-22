import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';

class DeliveriesTab extends StatefulWidget {
  const DeliveriesTab({super.key});
  @override
  State<DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<DeliveriesTab> {
  String _filter = 'Pendentes';
  String _dateFilter = 'Hoje'; // 'Hoje', 'Ontem', '7 Dias', 'Mês', 'Todas'

  void _openDeliveryDispatchDialog(SavedQuote quote) {
    final Map<String, TextEditingController> controllers = {};
    for (var item in quote.items) {
      controllers[item.product.name] =
          TextEditingController(text: item.remainingQuantity.toString());
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Dar Baixa na Entrega: ${quote.clientName}'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Informe a quantidade de cada material que está saindo agora:'),
                const SizedBox(height: 12),
                ...quote.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  'Total: ${item.quantity} | Já Entregue: ${item.deliveredQuantity} | Restam: ${item.remainingQuantity}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: controllers[item.product.name],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final Map<String, int> batch = {};
              for (var item in quote.items) {
                final qty =
                    int.tryParse(controllers[item.product.name]?.text ?? '0') ??
                        0;
                batch[item.product.name] = qty;
              }
              context.read<AppProvider>().registerDeliveryBatch(quote, batch);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Baixa de entrega registrada com sucesso!'),
                    backgroundColor: Colors.green),
              );
            },
            child: const Text('Confirmar Saída'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final primaryColor = provider.primaryColor;
    final now = DateTime.now();

    final filtered = provider.quotes.where((q) {
      // Filtro de status de entrega
      if (_filter == 'Pendentes' && q.isFullyDelivered) return false;
      if (_filter == 'Concluídas' && !q.isFullyDelivered) return false;

      // Filtro de data
      final targetDate = q.scheduledDeliveryDate ?? q.createdAt;
      if (_dateFilter == 'Hoje') {
        return targetDate.day == now.day &&
            targetDate.month == now.month &&
            targetDate.year == now.year;
      }
      if (_dateFilter == 'Ontem') {
        final yesterday = now.subtract(const Duration(days: 1));
        return targetDate.day == yesterday.day &&
            targetDate.month == yesterday.month &&
            targetDate.year == yesterday.year;
      }
      if (_dateFilter == '7 Dias') {
        return targetDate.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (_dateFilter == 'Mês') {
        return targetDate.month == now.month && targetDate.year == now.year;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Data: ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ...['Hoje', 'Ontem', '7 Dias', 'Mês', 'Todas'].map((df) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(df),
                      selected: _dateFilter == df,
                      onSelected: (sel) =>
                          setState(() => _dateFilter = sel ? df : 'Todas'),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                const Text('Status: ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ...['Pendentes', 'Concluídas', 'Todas'].map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (sel) =>
                          setState(() => _filter = sel ? f : 'Pendentes'),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Nenhuma entrega para o período selecionado.'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final q = filtered[i];
                      final isComplete = q.isFullyDelivered;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isComplete ? Colors.green[50] : Colors.blue[50],
                            child: Icon(
                              isComplete
                                  ? Icons.check_circle
                                  : Icons.local_shipping,
                              color: isComplete ? Colors.green : primaryColor,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(q.clientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isComplete
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isComplete
                                      ? 'Entregue Completo'
                                      : (q.deliveryType == 'partial'
                                          ? 'Entrega em Partes'
                                          : 'Agendada'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isComplete
                                        ? Colors.green[800]
                                        : Colors.orange[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Endereço: ${q.address.isNotEmpty ? q.address : "Retirada no Balcão"}'),
                              if (q.scheduledDeliveryDate != null)
                                Text(
                                  'Agendado para: ${q.scheduledDeliveryDate!.day}/${q.scheduledDeliveryDate!.month}/${q.scheduledDeliveryDate!.year} às ${q.scheduledDeliveryDate!.hour.toString().padLeft(2, '0')}:${q.scheduledDeliveryDate!.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Materiais e Status de Saída:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ...q.items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              '${item.quantity}x ${item.product.name}'),
                                          Text(
                                            'Entregue: ${item.deliveredQuantity}/${item.quantity} (${item.remainingQuantity} restantes)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: item.isFullyDelivered
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                  if (!isComplete)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white),
                                        icon:
                                            const Icon(Icons.outbox, size: 16),
                                        label: const Text(
                                            'Dar Baixa nos Materiais'),
                                        onPressed: () =>
                                            _openDeliveryDispatchDialog(q),
                                      ),
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
