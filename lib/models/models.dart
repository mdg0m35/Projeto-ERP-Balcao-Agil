import 'package:flutter/material.dart';

class Product {
  final String id;
  String name;
  String category;
  double costPrice;
  double price;
  int stock;
  String unit;
  double weightKg;
  IconData iconData;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.price,
    required this.stock,
    required this.unit,
    this.weightKg = 0.0,
    this.iconData = Icons.inventory_2,
  });
}

class CartItem {
  final Product product;
  int quantity;
  int deliveredQuantity;
  String? note;

  CartItem({
    required this.product,
    required this.quantity,
    this.deliveredQuantity = 0,
    this.note,
  });

  int get remainingQuantity =>
      (quantity - deliveredQuantity).clamp(0, quantity);
  bool get isFullyDelivered => deliveredQuantity >= quantity;
}

class SavedQuote {
  final String id;
  final String clientName;
  final String clientPhone;
  final String address;
  final DateTime createdAt;
  final List<CartItem> items;
  final double discountPercent;
  final double deliveryFee;
  String status;
  String deliveryType;
  DateTime? scheduledDeliveryDate;

  SavedQuote({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.address,
    required this.createdAt,
    required this.items,
    required this.discountPercent,
    required this.deliveryFee,
    required this.status,
    this.deliveryType = 'immediate',
    this.scheduledDeliveryDate,
  });

  double get subtotal =>
      items.fold(0, (sum, i) => sum + (i.product.price * i.quantity));
  double get discountAmount => subtotal * (discountPercent / 100);
  double get finalTotal => subtotal - discountAmount + deliveryFee;

  bool get isFullyDelivered => items.every((i) => i.isFullyDelivered);
}

class SupplierOrder {
  final String id;
  final String storeId;
  String supplierName;
  String supplierPhone;
  String description;
  double totalAmount; // Custo total pago ao fornecedor
  double paidAmount; // Valor pago até agora
  double expectedSalesAmount; // Valor total de faturamento projetado da revenda
  String deliveryStatus;
  String paymentStatus;
  DateTime? expectedDeliveryDate;
  String? notes;
  DateTime createdAt;

  SupplierOrder({
    required this.id,
    required this.storeId,
    required this.supplierName,
    required this.supplierPhone,
    required this.description,
    required this.totalAmount,
    required this.paidAmount,
    this.expectedSalesAmount = 0.0,
    this.deliveryStatus = 'Aguardando Entrega',
    this.paymentStatus = 'Pendente',
    this.expectedDeliveryDate,
    this.notes,
    required this.createdAt,
  });

  double get remainingBalance =>
      (totalAmount - paidAmount).clamp(0, totalAmount);
  double get projectedProfit => (expectedSalesAmount - totalAmount);
  double get profitMarginPercent => expectedSalesAmount > 0
      ? ((projectedProfit / expectedSalesAmount) * 100)
      : 0.0;
}

class StoreProfile {
  String name;
  String phone;
  String address;
  String pixKey;
  int colorValue;
  double monthlyFixedExpenses;
  double estimatedMonthlyRevenue;

  StoreProfile({
    this.name = 'Minha Loja',
    this.phone = '',
    this.address = '',
    this.pixKey = '',
    this.colorValue = 0xFF1E40AF,
    this.monthlyFixedExpenses = 3500.0,
    this.estimatedMonthlyRevenue = 30000.0,
  });

  double get fixedCostRate {
    if (estimatedMonthlyRevenue <= 0) return 0.12;
    return (monthlyFixedExpenses / estimatedMonthlyRevenue).clamp(0.05, 0.40);
  }
}
