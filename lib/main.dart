import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_screen.dart';

const String supabaseUrl = 'https://sua-url-aqui.supabase.co';
const String supabaseAnonKey = 'sua-anon-key-aqui';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const MaterialSaaSApp(),
    ),
  );
}

class MaterialSaaSApp extends StatelessWidget {
  const MaterialSaaSApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        context.select<AppProvider, Color>((p) => p.primaryColor);

    return MaterialApp(
      title: 'Balcão Ágil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // 1. Se o funcionário estiver com sessão ativa no provider ou localStorage
    if (provider.storeId.isNotEmpty) {
      return const MainScreen();
    }

    // 2. Se for o Administrador/Dono nativo
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AppProvider>().initializeSupabaseData();
          });
          return const MainScreen();
        }

        return const AuthScreen();
      },
    );
  }
}
