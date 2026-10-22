import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class PricingTab extends StatefulWidget {
  const PricingTab({super.key});

  @override
  State<PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<PricingTab> {
  final _rentCtrl = TextEditingController(text: '1800');
  final _energyCtrl = TextEditingController(text: '350');
  final _waterCtrl = TextEditingController(text: '80');
  final _internetCtrl = TextEditingController(text: '120');
  final _payrollCtrl = TextEditingController(text: '2000');
  final _fuelCtrl = TextEditingController(text: '500');
  final _otherCtrl = TextEditingController(text: '250');
  final _revenueCtrl = TextEditingController(text: '30000');

  double get _totalFixedCosts {
    final rent = double.tryParse(_rentCtrl.text.replaceAll(',', '.')) ?? 0;
    final energy = double.tryParse(_energyCtrl.text.replaceAll(',', '.')) ?? 0;
    final water = double.tryParse(_waterCtrl.text.replaceAll(',', '.')) ?? 0;
    final internet =
        double.tryParse(_internetCtrl.text.replaceAll(',', '.')) ?? 0;
    final payroll =
        double.tryParse(_payrollCtrl.text.replaceAll(',', '.')) ?? 0;
    final fuel = double.tryParse(_fuelCtrl.text.replaceAll(',', '.')) ?? 0;
    final other = double.tryParse(_otherCtrl.text.replaceAll(',', '.')) ?? 0;
    return rent + energy + water + internet + payroll + fuel + other;
  }

  double get _estimatedRevenue {
    final rev = double.tryParse(_revenueCtrl.text.replaceAll(',', '.')) ?? 0;
    return rev <= 0 ? 1 : rev;
  }

  double get _fixedExpenseRate =>
      (_totalFixedCosts / _estimatedRevenue).clamp(0.01, 0.60);

  void _saveEstimates() {
    final provider = context.read<AppProvider>();
    final newProfile = provider.storeProfile;
    newProfile.monthlyFixedExpenses = _totalFixedCosts;
    newProfile.estimatedMonthlyRevenue =
        double.tryParse(_revenueCtrl.text.replaceAll(',', '.')) ?? 30000;
    provider.updateStoreProfile(newProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Valores de custos salvos com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isMobile = MediaQuery.of(context).size.width < 900;
    final now = DateTime.now();

    // 1. Pega somente as vendas finalizadas no mês atual
    final monthlySales = provider.quotes.where((q) {
      return q.status == 'Finalizado' &&
          q.createdAt.month == now.month &&
          q.createdAt.year == now.year;
    }).toList();

    // 2. Faturamento e custos das mercadorias vendidas
    final double monthlyRevenue =
        monthlySales.fold(0.0, (sum, q) => sum + q.finalTotal);
    final double monthlyProductCosts = monthlySales.fold(0.0, (sum, q) {
      return sum +
          q.items.fold(0.0, (s, i) => s + (i.product.costPrice * i.quantity));
    });

    // 3. Margem bruta gerada pelas vendas
    final double grossMargin = monthlyRevenue - monthlyProductCosts;
    final double totalExpenses = _totalFixedCosts;
    final double progress =
        totalExpenses > 0 ? (grossMargin / totalExpenses).clamp(0.0, 1.0) : 0.0;
    final bool isCovered = grossMargin >= totalExpenses && totalExpenses > 0;
    final double remaining =
        (totalExpenses - grossMargin).clamp(0.0, totalExpenses);
    final double surplus = isCovered ? (grossMargin - totalExpenses) : 0.0;

    // CARD ESQUERDO: CUSTOS FIXOS DO DEPÓSITO
    final expensesCard = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.deepOrange),
                SizedBox(width: 8),
                Text(
                  'Custos Fixos Mensais do Depósito',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Preencha a média mensal dos gastos da sua loja para acompanhar a meta de cobertura no mês.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildInput('Aluguel (R\$)', _rentCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _buildInput('Energia (R\$)', _energyCtrl)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildInput('Água (R\$)', _waterCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _buildInput('Internet (R\$)', _internetCtrl)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _buildInput(
                        'Salários / Ajudantes (R\$)', _payrollCtrl)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildInput('Combustível / Frete (R\$)', _fuelCtrl)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _buildInput('Outras Despesas (R\$)', _otherCtrl)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildInput(
                        'Faturamento Estimado (R\$)', _revenueCtrl)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total de Contas Fixas:',
                          style: TextStyle(fontSize: 12, color: Colors.brown)),
                      Text(
                        'R\$ ${_totalFixedCosts.toStringAsFixed(2)} / mês',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.brown),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Impacto nas Vendas:',
                          style: TextStyle(fontSize: 12, color: Colors.brown)),
                      Text(
                        '${(_fixedExpenseRate * 100).toStringAsFixed(1)}% de cada venda',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.brown),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16192E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Salvar Custos'),
                onPressed: _saveEstimates,
              ),
            ),
          ],
        ),
      ),
    );

    // CARD DIREITO: O TERMÔMETRO DE METAS EM TEMPO REAL
    final thermometerCard = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCovered ? Colors.green.shade300 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCovered ? Icons.verified : Icons.speed_rounded,
                  color: isCovered ? Colors.green : Colors.orange,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCovered
                        ? '🎉 Custos Pagos!'
                        : 'Termômetro de Custos do Mês',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCovered
                          ? Colors.green[800]
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCovered ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isCovered ? Colors.green[900] : Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Acompanhe o faturamento do mês atual (${now.month.toString().padLeft(2, '0')}/${now.year}) até cobrir todas as despesas da loja.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 18,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCovered ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCovered
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isCovered ? Colors.green.shade200 : Colors.amber.shade200,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Faturado no Mês:',
                          style:
                              TextStyle(fontSize: 13, color: Colors.black87)),
                      Text(
                        'R\$ ${monthlyRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Custo das Mercadorias Vendidas:',
                          style:
                              TextStyle(fontSize: 13, color: Colors.black87)),
                      Text(
                        '- R\$ ${monthlyProductCosts.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.redAccent),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Margem Gerada p/ Pagar Contas:',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(
                        'R\$ ${grossMargin.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCovered
                              ? Colors.green[800]
                              : Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Meta de Custos Fixos:',
                          style:
                              TextStyle(fontSize: 13, color: Colors.black87)),
                      Text(
                        'R\$ ${totalExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCovered ? Colors.green[50] : Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isCovered ? Icons.check_circle : Icons.info_outline,
                    color: isCovered ? Colors.green : Colors.blueGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCovered
                          ? 'Todas as contas fixas do mês já foram pagas pelas vendas! Você já tem R\$ ${surplus.toStringAsFixed(2)} de lucro livre.'
                          : 'Ainda faltam R\$ ${remaining.toStringAsFixed(2)} de margem nas vendas para zerar os custos deste mês.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCovered
                            ? Colors.green[900]
                            : Colors.blueGrey[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: isMobile
          ? Column(
              children: [
                thermometerCard,
                const SizedBox(height: 16),
                expensesCard,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: expensesCard),
                const SizedBox(width: 20),
                Expanded(child: thermometerCard),
              ],
            ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
