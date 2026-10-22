import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_provider.dart';

class TeamTab extends StatefulWidget {
  const TeamTab({super.key});
  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  String _cleanErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return error.message;
    }
    final raw = error.toString();
    if (raw.contains('Este e-mail já está cadastrado')) {
      return 'Este e-mail já está cadastrado no sistema.';
    }
    if (raw.contains('pelo menos 6')) {
      return 'A senha deve conter no mínimo 6 dígitos.';
    }
    return 'Não foi possível concluir a operação. Verifique os dados.';
  }

  Future<void> _loadTeam() async {
    final storeId = context.read<AppProvider>().storeId;
    if (storeId.isEmpty) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('store_id', storeId);
      if (mounted) {
        setState(() => _members = List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      debugPrint('Erro ao carregar equipe: $e');
    }
  }

  Future<void> _copyAccessLink(Map<String, dynamic> member) async {
    try {
      final provider = context.read<AppProvider>();
      String token = member['access_token'] ?? '';

      // Se não tiver token gravado ainda, regenera na hora
      if (token.isEmpty) {
        final res = await Supabase.instance.client.rpc(
          'regenerate_employee_token',
          params: {
            'p_employee_id': member['id'],
            'p_store_id': provider.storeId,
          },
        );
        token = res.toString();
        await _loadTeam();
      }

      final baseUrl = Uri.base.origin;
      final directLink = '$baseUrl/?access_token=$token';
      final email = member['email'] ?? '';
      final pass = member['pin_code'] ?? 'Sua senha';

      final inviteMsg = '''
Olá *${member['full_name']}*! Aqui está o seu acesso ao sistema *${provider.storeProfile.name}*:

🚀 *Entrar Direto (Sem senha):*
$directLink

Ou acesse normalmente:
🔗 *Link:* $baseUrl
📧 *E-mail:* $email
🔑 *Senha:* $pass
'''
          .trim();

      await Clipboard.setData(ClipboardData(text: inviteMsg));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link de Acesso Direto copiado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar link: ${_cleanErrorMessage(e)}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addEmployee() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Preencha nome, e-mail e uma senha de no mínimo 6 dígitos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final provider = context.read<AppProvider>();
      final client = Supabase.instance.client;

      final res = await client.rpc('create_employee', params: {
        'p_store_id': provider.storeId,
        'p_full_name': name,
        'p_email': email,
        'p_password': pass,
      });

      final token = res['token'] ?? '';
      final baseUrl = Uri.base.origin;
      final directLink = '$baseUrl/?access_token=$token';

      final inviteMsg = '''
Olá *$name*! O seu acesso ao sistema *${provider.storeProfile.name}* foi criado:

🚀 *Entrar Direto (Sem Senha):*
$directLink

Ou pelo login tradicional:
🔗 *Link:* $baseUrl
📧 *E-mail:* $email
🔑 *Senha:* $pass
'''
          .trim();

      await Clipboard.setData(ClipboardData(text: inviteMsg));

      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
      await _loadTeam();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionário cadastrado! Link de acesso copiado.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_cleanErrorMessage(e)),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDeleteEmployee(Map<String, dynamic> member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Funcionário'),
        content: Text(
          'Deseja remover o acesso de "${member['full_name']}"?\nEle não conseguirá mais entrar na sua loja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, Remover'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final provider = context.read<AppProvider>();
        await Supabase.instance.client.rpc('delete_employee', params: {
          'p_employee_id': member['id'],
          'p_store_id': provider.storeId,
        });

        await _loadTeam();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionário removido com sucesso.'),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover: ${_cleanErrorMessage(e)}'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final primaryColor = context.watch<AppProvider>().primaryColor;

    final formCard = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cadastrar Novo Funcionário',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gera um link direto no WhatsApp para o vendedor entrar sem senha.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do Funcionário',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail de Login',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha Provisória (mín. 6 dígitos)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.link, size: 18),
                label: const Text('Criar Acesso e Copiar Link Direto'),
                onPressed: _loading ? null : _addEmployee,
              ),
            ),
          ],
        ),
      ),
    );

    final listCard = Card(
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
            const Text(
              'Equipe com Acesso',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child:
                    Center(child: Text('Nenhum funcionário cadastrado ainda.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _members.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, i) {
                  final m = _members[i];
                  final isOwner = m['role'] == 'owner';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isOwner ? primaryColor : Colors.blueGrey,
                      child: Icon(
                        isOwner ? Icons.star : Icons.badge_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      m['full_name'] ?? 'Sem nome',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        isOwner ? 'Administrador (Dono)' : 'Vendedor / Balcão'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isOwner) ...[
                          IconButton(
                            icon: const Icon(Icons.share,
                                color: Colors.blueAccent),
                            tooltip: 'Copiar Link de Acesso Direto',
                            onPressed: () => _copyAccessLink(m),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            tooltip: 'Remover Acesso',
                            onPressed: () => _confirmDeleteEmployee(m),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            formCard,
            const SizedBox(height: 16),
            listCard,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: formCard),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: SingleChildScrollView(child: listCard)),
        ],
      ),
    );
  }
}
