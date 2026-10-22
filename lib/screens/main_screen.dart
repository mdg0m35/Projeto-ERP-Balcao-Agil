import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'tabs/pos_tab.dart';
import 'tabs/quotes_tab.dart';
import 'tabs/deliveries_tab.dart';
import 'tabs/stock_tab.dart';
import 'tabs/suppliers_tab.dart';
import 'tabs/pricing_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/team_tab.dart';
import '../widgets/dialogs/settings_dialog.dart';
import '../widgets/dialogs/calculator_dialog.dart';
import '../widgets/dialogs/add_product_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final primaryColor = provider.primaryColor;
    final isOwner = provider.isOwner;
    final isMobile = MediaQuery.of(context).size.width < 900;

    final List<Widget> tabs = [
      const PosTab(),
      const QuotesTab(),
      const DeliveriesTab(),
      const StockTab(),
      if (isOwner) const SuppliersTab(),
      if (isOwner) const PricingTab(),
      if (isOwner) const AnalyticsTab(),
      if (isOwner) const TeamTab(),
    ];

    final List<String> tabTitles = [
      'PDV / Balcão',
      'Orçamentos',
      'Entregas',
      'Estoque',
      if (isOwner) 'Compras',
      if (isOwner) 'Custos & Preço',
      if (isOwner) 'Dashboard',
      if (isOwner) 'Equipe',
    ];

    Widget buildDrawerContent() {
      return Container(
        width: 250,
        color: const Color(0xFF16192E),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_cart,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.storeProfile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Olá, ${provider.currentUserName}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildNavItem(0, Icons.storefront_outlined, 'PDV / Balcão'),
                  _buildNavItem(1, Icons.receipt_long_outlined, 'Orçamentos'),
                  _buildNavItem(2, Icons.local_shipping_outlined, 'Entregas'),
                  _buildNavItem(
                    3,
                    Icons.inventory_2_outlined,
                    'Estoque',
                    badge: provider.products.where((p) => p.stock <= 0).length,
                  ),
                  if (isOwner) ...[
                    _buildNavItem(
                        4, Icons.fire_truck_outlined, 'Compras / Fornec.'),
                    _buildNavItem(
                        5, Icons.price_change_outlined, 'Custos & Preço'),
                    _buildNavItem(
                        6, Icons.analytics_outlined, 'Dashboard & Lucro'),
                    _buildNavItem(7, Icons.people_outline, 'Minha Equipe'),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Icons.settings_outlined,
                  color: Colors.white70, size: 20),
              title: const Text('Configurações',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              onTap: () {
                if (isMobile) Navigator.pop(context);
                showDialog(
                    context: context, builder: (_) => const SettingsDialog());
              },
            ),
            ListTile(
              dense: true,
              leading:
                  const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              title: const Text('Sair da Conta',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              onTap: () => provider.logout(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    // TopBar 100% responsiva (sem overflow no mobile)
    final topBar = Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            Builder(
              builder: (ctx) => IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              tabTitles[_currentIndex.clamp(0, tabTitles.length - 1)],
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Botão Calculadora adaptado para mobile (apenas ícone se for tela pequena)
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.calculate_outlined,
                  color: Color(0xFF1E293B)),
              tooltip: 'Calculadora',
              onPressed: () {
                showDialog(
                    context: context, builder: (_) => const CalculatorDialog());
              },
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E293B),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Calculadora',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              onPressed: () {
                showDialog(
                    context: context, builder: (_) => const CalculatorDialog());
              },
            ),
          const SizedBox(width: 6),
          // Botão Novo Produto adaptado para mobile
          if (isOwner)
            isMobile
                ? IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Novo Produto',
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (_) => const AddProductDialog());
                    },
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Novo Produto',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (_) => const AddProductDialog());
                    },
                  ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor.withOpacity(0.15),
              child: Text(
                provider.currentUserName.isNotEmpty
                    ? provider.currentUserName[0].toUpperCase()
                    : 'U',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.currentUserName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  isOwner ? 'Administrador' : 'Vendedor',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile ? Drawer(child: buildDrawerContent()) : null,
      body: Row(
        children: [
          if (!isMobile) buildDrawerContent(),
          Expanded(
            child: Column(
              children: [
                topBar,
                Expanded(
                  child: tabs[_currentIndex.clamp(0, tabs.length - 1)],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _currentIndex.clamp(0, (isOwner ? 7 : 3)),
              onTap: (idx) => setState(() => _currentIndex = idx),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey,
              items: [
                const BottomNavigationBarItem(
                    icon: Icon(Icons.storefront), label: 'Balcão'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long), label: 'Orçamentos'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.local_shipping), label: 'Entregas'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.inventory_2), label: 'Estoque'),
                if (isOwner) ...[
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.fire_truck), label: 'Compras'),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.price_change), label: 'Preços'),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.analytics), label: 'Lucro'),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.people), label: 'Equipe'),
                ],
              ],
            )
          : null,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {int badge = 0}) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon,
            color: isSelected ? Colors.white : Colors.white60, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        trailing: badge > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: () {
          setState(() => _currentIndex = index);
          if (MediaQuery.of(context).size.width < 900) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
