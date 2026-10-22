import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_provider.dart';
import '../main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isAdminRegistration = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDirectAccessToken();
    });
  }

  Future<void> _checkDirectAccessToken() async {
    String? token = Uri.base.queryParameters['access_token'];
    if (token == null && Uri.base.fragment.isNotEmpty) {
      final fragmentUri = Uri.tryParse('http://dummy/?${Uri.base.fragment}');
      token = fragmentUri?.queryParameters['access_token'];
    }

    if (token != null && token.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final res = await Supabase.instance.client.rpc(
          'login_with_token',
          params: {'p_token': token},
        );

        if (res != null && res['success'] == true && mounted) {
          final provider = context.read<AppProvider>();
          await provider.setEmployeeSession(
            storeId: res['store_id'].toString(),
            userName: res['full_name']?.toString() ?? 'Funcionário',
            role: 'employee',
          );

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          }
        } else if (mounted) {
          _showErrorDialog(
            'Link Inválido',
            res?['message']?.toString() ??
                'O link de acesso utilizado é inválido ou expirou.',
          );
        }
      } catch (e) {
        debugPrint('Erro ao autenticar com token direto: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _isLoading = false);
      _showErrorDialog('Campos incompletos', 'Preencha o e-mail e a senha.');
      return;
    }

    try {
      if (_isLogin) {
        bool loggedIn = false;

        // 1. Tenta login como Administrador nativo
        try {
          final authRes =
              await Supabase.instance.client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          if (authRes.user != null) {
            loggedIn = true;
          }
        } catch (_) {}

        // 2. Se não for Administrador, valida se é Funcionário
        if (!loggedIn) {
          final res = await Supabase.instance.client.rpc(
            'login_employee',
            params: {
              'p_email': email,
              'p_password': password,
            },
          );

          if (res != null && res['success'] == true && mounted) {
            final provider = context.read<AppProvider>();
            await provider.setEmployeeSession(
              storeId: res['store_id'].toString(),
              userName: res['full_name']?.toString() ?? 'Funcionário',
              role: 'employee',
            );
            loggedIn = true;

            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            }
          }
        }

        if (!loggedIn && mounted) {
          _showErrorDialog('Dados Incorretos', 'E-mail ou senha inválidos.');
        }
      } else {
        if (!_isAdminRegistration) {
          _showErrorDialog(
            'Acesso Restrito',
            'Funcionários devem ter o acesso criado pelo Administrador na aba Equipe.',
          );
          return;
        }

        final fullName = _fullNameCtrl.text.trim();
        final storeName = _storeNameCtrl.text.trim();

        if (fullName.isEmpty || storeName.isEmpty) {
          _showErrorDialog(
              'Campos incompletos', 'Preencha o nome da loja e o seu nome.');
          return;
        }

        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'store_name': storeName,
            'role': 'owner',
          },
        );

        if (res.user != null) {
          final storeData = await Supabase.instance.client
              .from('stores')
              .insert({'name': storeName})
              .select()
              .single();

          await Supabase.instance.client.from('profiles').upsert({
            'id': res.user!.id,
            'store_id': storeData['id'],
            'role': 'owner',
            'full_name': fullName,
          });
        }
      }
    } catch (e) {
      _showErrorDialog(
          'Aviso', 'Não foi possível autenticar. Verifique seus dados.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showErrorDialog('E-mail necessário',
          'Digite seu e-mail no campo para recuperar a senha.');
      return;
    }
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(_emailCtrl.text.trim());
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('📧 E-mail Enviado'),
            content: const Text(
                'Verifique sua caixa de entrada para redefinir sua senha.'),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(
          'Erro', 'Não foi possível enviar o e-mail de recuperação.');
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
    } catch (e) {
      _showErrorDialog(
          'Erro Google', 'Falha ao autenticar com a conta Google.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront, size: 60, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Bem-vindo ao Balcão' : 'Criar Conta da Loja',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                if (!_isLogin) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Você é o Administrador (Dono da Loja)?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Sim'),
                                value: true,
                                groupValue: _isAdminRegistration,
                                onChanged: (val) =>
                                    setState(() => _isAdminRegistration = val!),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Não'),
                                value: false,
                                groupValue: _isAdminRegistration,
                                onChanged: (val) =>
                                    setState(() => _isAdminRegistration = val!),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isAdminRegistration) ...[
                    TextField(
                      controller: _storeNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Depósito / Loja',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _fullNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Seu Nome (Dono)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Senha (mín. 6 letras)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text('Esqueceu a senha?',
                          style: TextStyle(fontSize: 13)),
                    ),
                  )
                else
                  const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Entrar no Sistema' : 'Criar Minha Loja',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                    ),
                    icon: const Icon(Icons.g_mobiledata,
                        size: 30, color: Colors.red),
                    label: const Text(
                      'Entrar com o Google',
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _loginWithGoogle,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? 'Não tem conta? Cadastre sua Loja'
                        : 'Já tem uma loja? Faça Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
