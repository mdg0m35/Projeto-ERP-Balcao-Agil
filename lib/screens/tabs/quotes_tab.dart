import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';

class QuotesTab extends StatefulWidget {
  const QuotesTab({super.key});
  @override
  State<QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<QuotesTab> {
  String _statusFilter = 'Todos';
  String _dateFilter = 'Hoje'; // 'Hoje', 'Ontem', '7 Dias', 'Mês', 'Todas'
  String _search = '';

  void _openFinalizeDialog(SavedQuote q) {
    String deliveryType = 'immediate';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Finalizar e Entregar Orçamento'),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Deseja marcar os materiais como entregues agora ou agendar?'),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('Entregue Completo (Agora)'),
                    value: 'immediate',
                    groupValue: deliveryType,
                    onChanged: (v) => setDState(() => deliveryType = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Agendar Entrega Futura'),
                    value: 'total',
                    groupValue: deliveryType,
                    onChanged: (v) => setDState(() => deliveryType = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Entregar em Partes'),
                    value: 'partial',
                    groupValue: deliveryType,
                    onChanged: (v) => setDState(() => deliveryType = v!),
                  ),
                  if (deliveryType != 'immediate') ...[
                    const Divider(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                          'Data: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setDState(() => selectedDate = d);
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  context.read<AppProvider>().updateQuoteStatus(
                        q,
                        'Finalizado',
                        deliveryType: deliveryType,
                        scheduledDate:
                            deliveryType != 'immediate' ? selectedDate : null,
                        isDeliveredComplete: deliveryType == 'immediate',
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Confirmar Finalização'),
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
    final now = DateTime.now();

    final filtered = provider.quotes.where((q) {
      final matchesSearch =
          q.clientName.toLowerCase().contains(_search.toLowerCase()) ||
              q.id.toLowerCase().contains(_search.toLowerCase());
      if (!matchesSearch) return false;

      // Filtro de status
      if (_statusFilter == 'Em andamento' && q.status != 'Em andamento')
        return false;
      if (_statusFilter == 'Finalizado' && q.status != 'Finalizado')
        return false;

      // Filtro de data
      if (_dateFilter == 'Hoje') {
        return q.createdAt.day == now.day &&
            q.createdAt.month == now.month &&
            q.createdAt.year == now.year;
      }
      if (_dateFilter == 'Ontem') {
        final yesterday = now.subtract(const Duration(days: 1));
        return q.createdAt.day == yesterday.day &&
            q.createdAt.month == yesterday.month &&
            q.createdAt.year == yesterday.year;
      }
      if (_dateFilter == '7 Dias') {
        return q.createdAt.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (_dateFilter == 'Mês') {
        return q.createdAt.month == now.month && q.createdAt.year == now.year;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de busca
          TextField(
            decoration: InputDecoration(
              hintText: 'Filtrar cliente ou código...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),

          // LINHA 1: STATUS DO ORÇAMENTO (Fixos, destacados e acessíveis no mobile)
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                      child: Text('Todos',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold))),
                  selected: _statusFilter == 'Todos',
                  onSelected: (sel) => setState(() => _statusFilter = 'Todos'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                      child: Text('Em andamento',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold))),
                  selected: _statusFilter == 'Em andamento',
                  selectedColor: Colors.orange.withOpacity(0.2),
                  onSelected: (sel) =>
                      setState(() => _statusFilter = 'Em andamento'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                      child: Text('Finalizados',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold))),
                  selected: _statusFilter == 'Finalizado',
                  selectedColor: Colors.green.withOpacity(0.2),
                  onSelected: (sel) =>
                      setState(() => _statusFilter = 'Finalizado'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // LINHA 2: FILTRO DE PERÍODO / DATA
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                ...['Hoje', 'Ontem', '7 Dias', 'Mês', 'Todas'].map((df) {
                  final isSelected = _dateFilter == df;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(df, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (sel) =>
                          setState(() => _dateFilter = sel ? df : 'Todas'),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // LISTAGEM DOS ORÇAMENTOS
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                        'Nenhum orçamento encontrado para os filtros selecionados.'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final q = filtered[i];
                      final isDone = q.status == 'Finalizado';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  q.clientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                              Text(
                                'R\$ ${q.finalTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color:
                                      isDone ? Colors.green[800] : primaryColor,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  q.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDone
                                        ? Colors.green[800]
                                        : Colors.orange[900],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Data: ${q.createdAt.day.toString().padLeft(2, '0')}/${q.createdAt.month.toString().padLeft(2, '0')}/${q.createdAt.year}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Itens do Orçamento:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor)),
                                  const SizedBox(height: 6),
                                  ...q.items.map((item) => Text(
                                        '${item.quantity}x ${item.product.name} - R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 13),
                                      )),
                                  const Divider(),
                                  if (!isDone)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                          icon:
                                              const Icon(Icons.check, size: 16),
                                          label:
                                              const Text('Finalizar Orçamento'),
                                          onPressed: () =>
                                              _openFinalizeDialog(q),
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
