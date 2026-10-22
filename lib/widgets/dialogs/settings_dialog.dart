import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/manual_pdf_generator.dart';
import '../../utils/csv_exporter.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});
  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _pixCtrl;
  late int _selectedColor;
  bool _isSaving = false;

  final List<int> _colors = [
    0xFF1E40AF,
    0xFFEF6C00,
    0xFF2E7D32,
    0xFF6A1B9A,
    0xFFC62828,
    0xFF0F172A,
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final p = provider.storeProfile;
    _nameCtrl = TextEditingController(text: p.name);
    _ownerNameCtrl = TextEditingController(text: provider.currentUserName);
    _phoneCtrl = TextEditingController(text: p.phone);
    _addressCtrl = TextEditingController(text: p.address);
    _pixCtrl = TextEditingController(text: p.pixKey);
    _selectedColor = p.colorValue;
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Excluir Conta Permanentemente?')),
          ],
        ),
        content: const Text(
          'ATENÇÃO: Todos os dados da sua loja, produtos, estoque, orçamentos e acessos serão APAGADOS PARA SEMPRE.\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, Excluir Tudo'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<AppProvider>();
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (provider.storeId.isNotEmpty) {
        await client.from('quotes').delete().eq('store_id', provider.storeId);
        await client.from('products').delete().eq('store_id', provider.storeId);
        await client.from('profiles').delete().eq('store_id', provider.storeId);
        await client.from('stores').delete().eq('id', provider.storeId);
      } else if (user != null) {
        await client.from('profiles').delete().eq('id', user.id);
      }

      try {
        await client.rpc('delete_user_account');
      } catch (_) {}

      await provider.logout();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.settings_suggest_rounded, size: 26),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Configurações do Sistema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DADOS DA EMPRESA E PERFIL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da Loja / Depósito',
                  prefixIcon: Icon(Icons.storefront_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ownerNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Seu Nome (Administrador)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Telefone / WhatsApp',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Endereço Completo',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pixCtrl,
                decoration: const InputDecoration(
                  labelText: 'Chave PIX para Recibos',
                  prefixIcon: Icon(Icons.pix_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'COR DE DESTAQUE DO SISTEMA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: _colors.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(c),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'AJUDA E DOCUMENTAÇÃO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.deepOrange,
                  ),
                  title: const Text(
                    'Manual de Uso do Sistema (PDF)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Clique para visualizar ou salvar o guia completo.',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: () => ManualPdfGenerator.generateAndDownloadManual(),
                ),
              ),
              const SizedBox(height: 16),

              // ===============================================================
              // BLOCO ADICIONADO: EXPORTAÇÃO COMPLETA PARA EXCEL / CSV
              // ===============================================================
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'EXPORTAR DADOS (BACKUP EXCEL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Faça o download de todos os seus dados em planilhas para continuar sua gestão no Excel a qualquer momento.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF15803D),
                        side: const BorderSide(color: Color(0xFF86EFAC)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.table_view_rounded, size: 18),
                      label: const Text(
                        'Produtos (.csv)',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        CsvExporter.downloadProductsCsv(
                          provider.products,
                          provider.storeProfile.name,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Planilha de produtos exportada com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1D4ED8),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text(
                        'Vendas (.csv)',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        CsvExporter.downloadQuotesCsv(
                          provider.quotes,
                          provider.storeProfile.name,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Planilha de vendas exportada com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // ===============================================================

              const SizedBox(height: 16),
              const Divider(),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                  icon: const Icon(Icons.delete_forever, size: 20),
                  label: const Text(
                    'Excluir minha conta e todos os dados',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () => _confirmAndDeleteAccount(context),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(_selectedColor),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _isSaving
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  try {
                    await context.read<AppProvider>().updateStoreProfile(
                          StoreProfile(
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            address: _addressCtrl.text.trim(),
                            pixKey: _pixCtrl.text.trim(),
                            colorValue: _selectedColor,
                          ),
                          newOwnerName: _ownerNameCtrl.text.trim(),
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Configurações e tema atualizados com sucesso!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setState(() => _isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao salvar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar Alterações'),
        ),
      ],
    );
  }
}
