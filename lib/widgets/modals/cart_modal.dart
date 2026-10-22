import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../models/models.dart';
import '../../providers/app_provider.dart';

class CartModal extends StatefulWidget {
  const CartModal({super.key});

  @override
  State<CartModal> createState() => _CartModalState();
}

class _CartModalState extends State<CartModal> {
  final _clientCtrl = TextEditingController(text: 'Cliente Balcão');
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(text: 'Retirada no Balcão');
  final _freightCtrl = TextEditingController(text: '0');
  double _discount = 0.0;

  void _shareViaWhatsApp(SavedQuote q, String storeName) {
    final cleanPhone = q.clientPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    buffer.writeln('📋 *Orçamento - $storeName*');
    buffer.writeln('👤 *Cliente:* ${q.clientName}');
    buffer.writeln('📍 *Entrega:* ${q.address}');
    buffer.writeln('--------------------------------');
    for (var item in q.items) {
      buffer.writeln(
          '▫️ ${item.quantity}x ${item.product.name} (R\$ ${item.product.price.toStringAsFixed(2)}) = R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}');
    }
    buffer.writeln('--------------------------------');
    if (q.discountPercent > 0) {
      buffer.writeln('📉 *Desconto:* ${q.discountPercent.toInt()}%');
    }
    if (q.deliveryFee > 0) {
      buffer.writeln('🚚 *Frete:* R\$ ${q.deliveryFee.toStringAsFixed(2)}');
    }
    buffer.writeln('💰 *Total Final:* R\$ ${q.finalTotal.toStringAsFixed(2)}');

    final text = Uri.encodeComponent(buffer.toString());
    final url = cleanPhone.isNotEmpty
        ? 'https://wa.me/55$cleanPhone?text=$text'
        : 'https://api.whatsapp.com/send?text=$text';
    html.window.open(url, '_blank');
  }

  // Salva diretamente como orçamento (sem popup de entrega)
  void _saveBudgetOnly({bool openWhatsApp = false}) {
    final provider = context.read<AppProvider>();
    final freight =
        double.tryParse(_freightCtrl.text.replaceAll(',', '.')) ?? 0;

    final quote = SavedQuote(
      id: '',
      clientName: _clientCtrl.text.trim().isEmpty
          ? 'Cliente Balcão'
          : _clientCtrl.text.trim(),
      clientPhone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      createdAt: DateTime.now(),
      items: List.from(provider.cart),
      discountPercent: _discount,
      deliveryFee: freight,
      status: 'Em andamento',
      deliveryType: 'immediate',
    );

    provider.saveQuote(
      quote,
      false, // false = não baixa estoque, apenas salva orçamento
      deliveryType: 'immediate',
      isDeliveredComplete: false,
    );

    if (openWhatsApp) {
      _shareViaWhatsApp(quote, provider.storeProfile.name);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(openWhatsApp
            ? 'Orçamento salvo e WhatsApp aberto!'
            : 'Orçamento salvo com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // APENAS PARA A VENDA: Abre o diálogo de entrega
  void _openDeliveryOptionForSale() {
    String deliveryType = 'immediate';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.point_of_sale_rounded, color: Color(0xFF1D4ED8)),
                SizedBox(width: 8),
                Text('Opções de Entrega da Venda'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Como será feita a entrega dos materiais?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text(
                        'Já foi entregue tudo (Imediato / Retirada)'),
                    subtitle: const Text(
                        'Itens saem do estoque e constam como entregues no balcão.'),
                    value: 'immediate',
                    groupValue: deliveryType,
                    onChanged: (v) => setDState(() => deliveryType = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Agendar Entrega Futura (Total)'),
                    subtitle: const Text(
                        'Será agendada uma data para entregar tudo de uma vez.'),
                    value: 'total',
                    groupValue: deliveryType,
                    onChanged: (v) => setDState(() => deliveryType = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Entrega em Partes (Conforme Obra)'),
                    subtitle: const Text(
                        'Cliente vai retirando ou recebendo os materiais aos poucos.'),
                    value: 'partial',
                    groupValue: deliveryType,
                    onChanged: (v) => setDState(() => deliveryType = v!),
                  ),
                  if (deliveryType != 'immediate') ...[
                    const Divider(),
                    const SizedBox(height: 6),
                    const Text('Data e Hora de Agendamento:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (d != null) setDState(() => selectedDate = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(selectedTime.format(context)),
                            onPressed: () async {
                              final t = await showTimePicker(
                                  context: context, initialTime: selectedTime);
                              if (t != null) setDState(() => selectedTime = t);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Voltar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _processFinalSale(deliveryType, selectedDate, selectedTime);
                },
                child: const Text('Confirmar Venda'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _processFinalSale(
      String deliveryType, DateTime scheduledDate, TimeOfDay time) {
    final provider = context.read<AppProvider>();
    final freight =
        double.tryParse(_freightCtrl.text.replaceAll(',', '.')) ?? 0;

    final fullSchedule = deliveryType != 'immediate'
        ? DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day,
            time.hour, time.minute)
        : null;

    final quote = SavedQuote(
      id: '',
      clientName: _clientCtrl.text.trim().isEmpty
          ? 'Cliente Balcão'
          : _clientCtrl.text.trim(),
      clientPhone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      createdAt: DateTime.now(),
      items: List.from(provider.cart),
      discountPercent: _discount,
      deliveryFee: freight,
      status: 'Finalizado',
      deliveryType: deliveryType,
      scheduledDeliveryDate: fullSchedule,
    );

    provider.saveQuote(
      quote,
      true, // true = baixa estoque e concretiza venda
      deliveryType: deliveryType,
      scheduledDate: fullSchedule,
      isDeliveredComplete: deliveryType == 'immediate',
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Venda realizada e registrada com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cart = provider.cart;
    final freight =
        double.tryParse(_freightCtrl.text.replaceAll(',', '.')) ?? 0;

    final subtotal = provider.totalBudget;
    final discountVal = subtotal * (_discount / 100);
    final total = subtotal - discountVal + freight;
    final totalWeight = provider.totalWeightKg;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Orçamento • ${provider.storeProfile.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 16, color: Color(0xFF1D4ED8)),
                            const SizedBox(width: 6),
                            Text(
                              'Carga Sist.: ${totalWeight.toStringAsFixed(1)}kg',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _clientCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cliente / Obra',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Cliente',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Endereço de Entrega',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              if (cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Nenhum item no carrinho.')),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = cart[i];
                      return ListTile(
                        leading:
                            Icon(item.product.iconData, color: Colors.blueGrey),
                        title: Text(item.product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          'R\$ ${item.product.price.toStringAsFixed(2)} x ${item.quantity} = R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () => provider.updateCartItem(item, 0),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.blueGrey, size: 20),
                              onPressed: () => provider.updateCartItem(
                                  item, item.quantity - 1),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${item.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Colors.green, size: 20),
                              onPressed: () => provider.updateCartItem(
                                  item, item.quantity + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Desconto:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 6,
                    children: [0.0, 5.0, 10.0].map((d) {
                      return ChoiceChip(
                        label: Text('${d.toInt()}%'),
                        selected: _discount == d,
                        onSelected: (sel) =>
                            setState(() => _discount = sel ? d : 0.0),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: _freightCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Frete (R\$)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Final:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'R\$ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // 1. SALVAR: Salva direto sem popup
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      icon: const Icon(Icons.bookmark_border, size: 18),
                      label: const Text('Salvar'),
                      onPressed: cart.isEmpty ? null : () => _saveBudgetOnly(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 2. VENDER: ÚNICO que abre o modal de opções de entrega
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Vender'),
                      onPressed:
                          cart.isEmpty ? null : _openDeliveryOptionForSale,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 3. WHATSAPP: Salva o orçamento direto e abre a conversa
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('WhatsApp'),
                      onPressed: cart.isEmpty
                          ? null
                          : () => _saveBudgetOnly(openWhatsApp: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
