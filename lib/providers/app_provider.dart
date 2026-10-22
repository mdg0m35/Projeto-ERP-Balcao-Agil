import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/models.dart';
import '../utils/helpers.dart';

class AppProvider extends ChangeNotifier {
  bool isOwner = false;
  String currentUserName = '';
  String storeId = '';
  StoreProfile storeProfile = StoreProfile();
  Color get primaryColor => Color(storeProfile.colorValue);

  List<Product> products = [];
  List<SavedQuote> _quotes = [];
  List<SupplierOrder> supplierOrders = [];
  List<CartItem> cart = [];
  bool _isInitializing = false;

  AppProvider() {
    _restoreSavedEmployeeSession();
  }

  void _restoreSavedEmployeeSession() {
    try {
      final saved = html.window.localStorage['employee_session'];
      if (saved != null && saved.isNotEmpty) {
        final data = jsonDecode(saved);
        setEmployeeSession(
          storeId: data['store_id'],
          userName: data['user_name'],
          role: data['role'],
        );
      }
    } catch (_) {}
  }

  Future<void> setEmployeeSession({
    required String storeId,
    required String userName,
    required String role,
  }) async {
    this.storeId = storeId;
    currentUserName = userName;
    isOwner = (role == 'owner');

    try {
      html.window.localStorage['employee_session'] = jsonEncode({
        'store_id': storeId,
        'user_name': userName,
        'role': role,
      });
    } catch (_) {}

    if (this.storeId.isNotEmpty) {
      await _loadStoreDetails();
    }

    await fetchProducts();
    await fetchQuotes();
    await fetchSupplierOrders();
    notifyListeners();
  }

  Future<void> _loadStoreDetails() async {
    try {
      final store = await Supabase.instance.client
          .from('stores')
          .select()
          .eq('id', storeId)
          .maybeSingle();

      if (store != null) {
        storeProfile.name = store['name'] ?? 'Minha Loja';
        storeProfile.phone = store['phone'] ?? '';
        storeProfile.address = store['address'] ?? '';
        storeProfile.pixKey = store['pix_key'] ?? '';
        final rawColor = store['theme_color'] ?? store['color_value'];
        storeProfile.colorValue = rawColor != null
            ? int.tryParse(rawColor.toString()) ?? 0xFF1E40AF
            : 0xFF1E40AF;
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados da loja: $e');
    }
  }

  Future<void> initializeSupabaseData() async {
    if (_isInitializing) return;
    _isInitializing = true;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _isInitializing = false;
      return;
    }

    final typedFullName =
        user.userMetadata?['full_name']?.toString().trim() ?? '';
    final typedStoreName =
        user.userMetadata?['store_name']?.toString().trim() ?? '';
    final typedRole = user.userMetadata?['role']?.toString().trim() ?? 'owner';

    try {
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id);

      if ((profileRes as List).isNotEmpty) {
        final profile = profileRes.first;
        isOwner = profile['role'] == 'owner';
        storeId = profile['store_id'].toString();
        final savedName = profile['full_name']?.toString().trim() ?? '';
        currentUserName = savedName.isNotEmpty
            ? savedName
            : (typedFullName.isNotEmpty ? typedFullName : 'Administrador');
      } else {
        final finalStoreName =
            typedStoreName.isNotEmpty ? typedStoreName : 'Minha Loja';
        final finalUserName =
            typedFullName.isNotEmpty ? typedFullName : 'Administrador';

        final storeRes = await Supabase.instance.client
            .from('stores')
            .insert({'name': finalStoreName})
            .select()
            .single();
        storeId = storeRes['id'].toString();
        isOwner = typedRole == 'owner';
        currentUserName = finalUserName;

        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'store_id': storeId,
          'role': typedRole,
          'full_name': finalUserName,
        });
      }

      if (storeId.isNotEmpty) {
        await _loadStoreDetails();
      }

      await fetchProducts();
      await fetchQuotes();
      await fetchSupplierOrders();
    } catch (e) {
      debugPrint('Aviso na inicializacao: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> fetchProducts() async {
    if (storeId.isEmpty) return;
    try {
      final res = await Supabase.instance.client
          .from('products')
          .select()
          .eq('store_id', storeId);

      products = (res as List).map((p) {
        final rawPrice = p['price'] ?? p['sale_price'] ?? 0;
        return Product(
          id: p['id'].toString(),
          name: p['name'] ?? '',
          category: p['category'] ?? 'Geral',
          costPrice: double.tryParse(p['cost_price']?.toString() ?? '0') ?? 0,
          price: double.tryParse(rawPrice.toString()) ?? 0,
          stock: int.tryParse(p['stock']?.toString() ?? '0') ?? 0,
          unit: p['unit'] ?? 'un',
          weightKg: double.tryParse(p['weight_kg']?.toString() ?? '0') ?? 0,
          iconData: detectIconForProduct(p['name'] ?? ''),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar produtos: $e');
    }
  }

  Future<void> fetchQuotes() async {
    if (storeId.isEmpty) return;
    try {
      final res = await Supabase.instance.client
          .from('quotes')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      _quotes = (res as List).map((q) {
        final rawList = (q['items_jsonb'] ?? q['items'] ?? []) as List;
        var itemsList = rawList.map((i) {
          final prod = products.firstWhere(
            (p) => p.name == i['product_name'],
            orElse: () => Product(
              id: '0',
              name: i['product_name'] ?? 'Item',
              category: 'Geral',
              costPrice: 0,
              price: double.tryParse(i['unit_price']?.toString() ?? '0') ?? 0,
              stock: 0,
              unit: i['unit'] ?? 'un',
            ),
          );
          return CartItem(
            product: prod,
            quantity: int.tryParse(i['quantity']?.toString() ?? '1') ?? 1,
            deliveredQuantity:
                int.tryParse(i['delivered_quantity']?.toString() ?? '0') ?? 0,
            note: i['note'],
          );
        }).toList();

        return SavedQuote(
          id: q['id'].toString(),
          clientName: q['client_name'] ?? q['customer_name'] ?? 'Cliente',
          clientPhone: q['client_phone'] ?? '',
          address: q['address'] ?? '',
          createdAt: DateTime.tryParse(q['created_at']?.toString() ?? '') ??
              DateTime.now(),
          items: itemsList,
          discountPercent:
              double.tryParse(q['discount_percent']?.toString() ?? '0') ?? 0,
          deliveryFee:
              double.tryParse(q['delivery_fee']?.toString() ?? '0') ?? 0,
          status: q['status'] ?? 'Pendente',
          deliveryType: q['delivery_type'] ?? 'immediate',
          scheduledDeliveryDate: q['scheduled_delivery_date'] != null
              ? DateTime.tryParse(q['scheduled_delivery_date'].toString())
              : null,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar orcamentos: $e');
    }
  }

  Future<void> fetchSupplierOrders() async {
    if (storeId.isEmpty) return;
    try {
      final res = await Supabase.instance.client
          .from('supplier_orders')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      supplierOrders = (res as List).map((s) {
        return SupplierOrder(
          id: s['id'].toString(),
          storeId: s['store_id'].toString(),
          supplierName: s['supplier_name'] ?? 'Fornecedor',
          supplierPhone: s['supplier_phone'] ?? '',
          description: s['description'] ?? '',
          totalAmount:
              double.tryParse(s['total_amount']?.toString() ?? '0') ?? 0,
          paidAmount: double.tryParse(s['paid_amount']?.toString() ?? '0') ?? 0,
          expectedSalesAmount:
              double.tryParse(s['expected_sales_amount']?.toString() ?? '0') ??
                  0,
          deliveryStatus: s['delivery_status'] ?? 'Aguardando Entrega',
          paymentStatus: s['payment_status'] ?? 'Pendente',
          expectedDeliveryDate: s['expected_delivery_date'] != null
              ? DateTime.tryParse(s['expected_delivery_date'].toString())
              : null,
          notes: s['notes'],
          createdAt: DateTime.tryParse(s['created_at']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar pedidos de fornecedores: $e');
    }
  }

  Future<void> addSupplierOrder(SupplierOrder order) async {
    if (storeId.isEmpty) return;
    final res = await Supabase.instance.client
        .from('supplier_orders')
        .insert({
          'store_id': storeId,
          'supplier_name': order.supplierName,
          'supplier_phone': order.supplierPhone,
          'description': order.description,
          'total_amount': order.totalAmount,
          'paid_amount': order.paidAmount,
          'expected_sales_amount': order.expectedSalesAmount,
          'delivery_status': order.deliveryStatus,
          'payment_status': order.paymentStatus,
          'expected_delivery_date':
              order.expectedDeliveryDate?.toIso8601String(),
          'notes': order.notes,
        })
        .select()
        .single();

    supplierOrders.insert(
      0,
      SupplierOrder(
        id: res['id'].toString(),
        storeId: storeId,
        supplierName: order.supplierName,
        supplierPhone: order.supplierPhone,
        description: order.description,
        totalAmount: order.totalAmount,
        paidAmount: order.paidAmount,
        expectedSalesAmount: order.expectedSalesAmount,
        deliveryStatus: order.deliveryStatus,
        paymentStatus: order.paymentStatus,
        expectedDeliveryDate: order.expectedDeliveryDate,
        notes: order.notes,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> updateSupplierOrder(SupplierOrder order) async {
    final idx = supplierOrders.indexWhere((o) => o.id == order.id);
    if (idx >= 0) {
      supplierOrders[idx] = order;
      notifyListeners();
      await Supabase.instance.client.from('supplier_orders').update({
        'supplier_name': order.supplierName,
        'supplier_phone': order.supplierPhone,
        'description': order.description,
        'total_amount': order.totalAmount,
        'paid_amount': order.paidAmount,
        'expected_sales_amount': order.expectedSalesAmount,
        'delivery_status': order.deliveryStatus,
        'payment_status': order.paymentStatus,
        'expected_delivery_date': order.expectedDeliveryDate?.toIso8601String(),
        'notes': order.notes,
      }).eq('id', order.id);
    }
  }

  Future<void> deleteSupplierOrder(String id) async {
    supplierOrders.removeWhere((o) => o.id == id);
    notifyListeners();
    await Supabase.instance.client
        .from('supplier_orders')
        .delete()
        .eq('id', id);
  }

  double calculateSuggestedPrice({
    required double costPrice,
    double desiredProfitMargin = 0.25,
  }) {
    if (costPrice <= 0) return 0.0;
    final fixedRate = storeProfile.fixedCostRate;
    final totalDeductions = (fixedRate + desiredProfitMargin).clamp(0.10, 0.80);
    return costPrice / (1.0 - totalDeductions);
  }

  Future<void> updateStoreProfile(StoreProfile np,
      {String? newOwnerName}) async {
    storeProfile = StoreProfile(
      name: np.name,
      phone: np.phone,
      address: np.address,
      pixKey: np.pixKey,
      colorValue: np.colorValue,
      monthlyFixedExpenses: np.monthlyFixedExpenses,
      estimatedMonthlyRevenue: np.estimatedMonthlyRevenue,
    );
    if (newOwnerName != null && newOwnerName.isNotEmpty) {
      currentUserName = newOwnerName;
    }
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (newOwnerName != null && newOwnerName.isNotEmpty && user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'full_name': newOwnerName}).eq('id', user.id);
    }

    if (storeId.isNotEmpty) {
      await Supabase.instance.client.from('stores').update({
        'name': np.name,
        'phone': np.phone,
        'address': np.address,
        'pix_key': np.pixKey,
        'theme_color': np.colorValue,
      }).eq('id', storeId);
    }
  }

  Future<void> addProduct(Product p) async {
    if (storeId.isEmpty) {
      await initializeSupabaseData();
    }
    if (storeId.isEmpty) {
      throw Exception('Loja nao identificada. Recarregue a pagina.');
    }

    final res = await Supabase.instance.client
        .from('products')
        .insert({
          'store_id': storeId,
          'name': p.name,
          'category': p.category,
          'cost_price': p.costPrice,
          'price': p.price,
          'stock': p.stock,
          'unit': p.unit,
          'weight_kg': p.weightKg,
        })
        .select()
        .single();

    products.insert(
      0,
      Product(
        id: res['id'].toString(),
        name: p.name,
        category: p.category,
        costPrice: p.costPrice,
        price: p.price,
        stock: p.stock,
        unit: p.unit,
        weightKg: p.weightKg,
        iconData: detectIconForProduct(p.name),
      ),
    );
    notifyListeners();
  }

  Future<void> updateProduct(Product p) async {
    final idx = products.indexWhere((item) => item.id == p.id);
    if (idx >= 0) {
      products[idx] = p;
      notifyListeners();
      await Supabase.instance.client.from('products').update({
        'name': p.name,
        'category': p.category,
        'cost_price': p.costPrice,
        'price': p.price,
        'stock': p.stock,
        'unit': p.unit,
        'weight_kg': p.weightKg,
      }).eq('id', p.id);
    }
  }

  Future<void> updateProductStock(String id, int stock) async {
    final idx = products.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      products[idx].stock = stock;
      notifyListeners();
      await Supabase.instance.client
          .from('products')
          .update({'stock': stock}).eq('id', id);
    }
  }

  void addToCart(Product p, int qty, {String? note}) {
    if (qty <= 0) return;
    final i = cart.indexWhere((item) => item.product.id == p.id);
    if (i >= 0) {
      cart[i].quantity += qty;
      if (note != null) cart[i].note = note;
    } else {
      cart.add(CartItem(product: p, quantity: qty, note: note));
    }
    notifyListeners();
  }

  void updateCartItem(CartItem item, int newQty) {
    if (newQty <= 0) {
      cart.remove(item);
    } else {
      item.quantity = newQty;
    }
    notifyListeners();
  }

  Future<void> saveQuote(
    SavedQuote q,
    bool finalizeSale, {
    String deliveryType = 'immediate',
    DateTime? scheduledDate,
    bool isDeliveredComplete = true,
  }) async {
    if (storeId.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    final sellerId = user?.id;

    List<Map<String, dynamic>> itemsJson = q.items
        .map((i) => {
              'product_name': i.product.name,
              'unit': i.product.unit,
              'unit_price': i.product.price,
              'quantity': i.quantity,
              'delivered_quantity':
                  isDeliveredComplete ? i.quantity : i.deliveredQuantity,
              'note': i.note,
            })
        .toList();

    await Supabase.instance.client.from('quotes').insert({
      'store_id': storeId,
      if (sellerId != null) 'seller_id': sellerId,
      'seller_name': currentUserName.isNotEmpty ? currentUserName : 'Balcao',
      'client_name': q.clientName,
      'client_phone': q.clientPhone,
      'address': q.address,
      'status': q.status,
      'discount_percent': q.discountPercent,
      'delivery_fee': q.deliveryFee,
      'total_amount': q.finalTotal,
      'delivery_type': deliveryType,
      'scheduled_delivery_date': scheduledDate?.toIso8601String(),
      'items_jsonb': itemsJson,
    });

    if (finalizeSale) {
      for (var item in q.items) {
        item.product.stock =
            (item.product.stock - item.quantity).clamp(0, 999999);
        await Supabase.instance.client
            .from('products')
            .update({'stock': item.product.stock})
            .eq('name', item.product.name)
            .eq('store_id', storeId);
      }
    }
    cart.clear();
    await fetchQuotes();
    notifyListeners();
  }

  Future<void> updateQuoteStatus(
    SavedQuote q,
    String status, {
    String? deliveryType,
    DateTime? scheduledDate,
    bool? isDeliveredComplete,
  }) async {
    q.status = status;
    if (deliveryType != null) q.deliveryType = deliveryType;
    if (scheduledDate != null) q.scheduledDeliveryDate = scheduledDate;

    if (isDeliveredComplete == true) {
      for (var item in q.items) {
        item.deliveredQuantity = item.quantity;
      }
    }

    List<Map<String, dynamic>> itemsJson = q.items
        .map((i) => {
              'product_name': i.product.name,
              'unit': i.product.unit,
              'unit_price': i.product.price,
              'quantity': i.quantity,
              'delivered_quantity': i.deliveredQuantity,
              'note': i.note,
            })
        .toList();

    await Supabase.instance.client.from('quotes').update({
      'status': status,
      if (deliveryType != null) 'delivery_type': deliveryType,
      if (scheduledDate != null)
        'scheduled_delivery_date': scheduledDate.toIso8601String(),
      'items_jsonb': itemsJson,
    }).eq('id', q.id);

    if (status == 'Finalizado') {
      for (var item in q.items) {
        item.product.stock =
            (item.product.stock - item.quantity).clamp(0, 999999);
        await Supabase.instance.client
            .from('products')
            .update({'stock': item.product.stock})
            .eq('name', item.product.name)
            .eq('store_id', storeId);
      }
    }
    await fetchQuotes();
    notifyListeners();
  }

  Future<void> registerDeliveryBatch(
      SavedQuote q, Map<String, int> deliveredNow) async {
    for (var item in q.items) {
      final added = deliveredNow[item.product.name] ?? 0;
      item.deliveredQuantity =
          (item.deliveredQuantity + added).clamp(0, item.quantity);
    }

    final allDone = q.isFullyDelivered;

    List<Map<String, dynamic>> itemsJson = q.items
        .map((i) => {
              'product_name': i.product.name,
              'unit': i.product.unit,
              'unit_price': i.product.price,
              'quantity': i.quantity,
              'delivered_quantity': i.deliveredQuantity,
              'note': i.note,
            })
        .toList();

    await Supabase.instance.client.from('quotes').update({
      'items_jsonb': itemsJson,
      if (allDone) 'delivery_type': 'completed',
    }).eq('id', q.id);

    notifyListeners();
  }

  Future<void> logout() async {
    try {
      html.window.localStorage.remove('employee_session');
    } catch (_) {}
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    isOwner = false;
    currentUserName = '';
    storeId = '';
    cart.clear();
    _quotes.clear();
    supplierOrders.clear();
    products.clear();
    notifyListeners();
  }

  List<SavedQuote> get quotes => _quotes;
  double get totalBudget =>
      cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get totalCost => cart.fold(
      0, (sum, item) => sum + (item.product.costPrice * item.quantity));
  double get totalWeightKg => cart.fold(
      0, (sum, item) => sum + (item.product.weightKg * item.quantity));
  int get totalItemsCount => cart.fold(0, (sum, item) => sum + item.quantity);
}
