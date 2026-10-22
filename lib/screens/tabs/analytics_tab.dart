import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _period = 'Hoje';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final primaryColor = provider.primaryColor;

    final quotes = provider.quotes.where((q) {
      if (q.status != 'Finalizado') return false;
      final now = DateTime.now();
      if (_period == 'Hoje') {
        return q.createdAt.day == now.day &&
            q.createdAt.month == now.month &&
            q.createdAt.year == now.year;
      }
      if (_period == '7 Dias') {
        return q.createdAt.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (_period == 'Mês') {
        return q.createdAt.month == now.month && q.createdAt.year == now.year;
      }
      return true;
    }).toList();

    double revenue = quotes.fold(0, (sum, q) => sum + q.finalTotal);
    double cost = quotes.fold(0, (sum, q) {
      return sum +
          q.items.fold(0.0, (s, i) => s + (i.product.costPrice * i.quantity));
    });
    double profit = revenue - cost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Hoje', '7 Dias', 'Mês', 'Tudo'].map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: _period == p,
                    onSelected: (sel) =>
                        setState(() => _period = sel ? p : 'Hoje'),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatCard(
                      'Faturamento',
                      'R\$ ${revenue.toStringAsFixed(2)}',
                      Icons.payments,
                      Colors.blue,
                      isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 24) / 3),
                  _buildStatCard(
                      'Custo dos Produtos',
                      'R\$ ${cost.toStringAsFixed(2)}',
                      Icons.money_off,
                      Colors.orange,
                      isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 24) / 3),
                  _buildStatCard(
                      'Lucro Líquido Estimado',
                      'R\$ ${profit.toStringAsFixed(2)}',
                      Icons.trending_up,
                      Colors.green,
                      isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 24) / 3),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Vendas Recentes do Período:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (quotes.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhuma venda computada neste período.')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quotes.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, i) {
                final q = quotes[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.receipt, color: primaryColor)),
                  title: Text(q.clientName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Data: ${q.createdAt.day}/${q.createdAt.month}/${q.createdAt.year} às ${q.createdAt.hour}:${q.createdAt.minute.toString().padLeft(2, '0')}'),
                  trailing: Text('R\$ ${q.finalTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String val, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(val,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
