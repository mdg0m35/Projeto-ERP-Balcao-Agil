import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});
  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  int calcTab = 0;
  final widthCtrl = TextEditingController(), lengthCtrl = TextEditingController(), thicknessCtrl = TextEditingController(text: '10'), boxCoverageCtrl = TextEditingController(text: '2.50');
  bool includeMargin = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final w = double.tryParse(widthCtrl.text.replaceAll(',', '.')) ?? 0;
    final l = double.tryParse(lengthCtrl.text.replaceAll(',', '.')) ?? 0;
    final areaWithMargin = includeMargin ? (w * l) * 1.10 : (w * l);
    final boxArea = double.tryParse(boxCoverageCtrl.text.replaceAll(',', '.')) ?? 2.5;
    final boxes = (w > 0 && l > 0 && boxArea > 0) ? (areaWithMargin / boxArea).ceil() : 0;
    final mortarBags = (w > 0 && l > 0) ? (areaWithMargin / 4.0).ceil() : 0;
    final bricksCount = (w > 0 && l > 0) ? (areaWithMargin * 25).ceil() : 0;
    final cementForWall = (bricksCount > 0) ? (bricksCount / 150).ceil() : 0;

    return AlertDialog(
      title: Row(children: [Icon(Icons.calculate, color: provider.primaryColor), const SizedBox(width: 8), const Text('Calculadora de Obras')]),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<int>(
              segments: const [ButtonSegment(value: 0, label: Text('Pisos')), ButtonSegment(value: 1, label: Text('Alvenaria'))],
              selected: {calcTab}, onSelectionChanged: (val) => setState(() => calcTab = val.first),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: widthCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Largura (m)'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: lengthCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Comprimento (m)'))),
            ]),
            const SizedBox(height: 12),
            if (calcTab == 0) TextField(controller: boxCoverageCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'm² por Caixa')),
            const SizedBox(height: 12),
            if (w > 0 && l > 0) Container(
              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
              child: Text(calcTab == 0 ? '📦 $boxes caixas de Piso\n🧱 $mortarBags sacos de Argamassa' : '🧱 $bricksCount Tijolos\n🪣 $cementForWall sacos de Cimento', style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: provider.primaryColor, foregroundColor: Colors.white),
          onPressed: (w <= 0 || l <= 0) ? null : () {
            if (calcTab == 0) {
              provider.addToCart(provider.products.firstWhere((p) => p.name.contains('Piso'), orElse: () => provider.products.first), boxes, note: 'Cálculo Piso');
            } else {
              provider.addToCart(provider.products.firstWhere((p) => p.name.contains('Tijolo'), orElse: () => provider.products.first), bricksCount, note: 'Cálculo Tijolo');
            }
            Navigator.pop(context);
          },
          child: const Text('Lançar'),
        )
      ],
    );
  }
}