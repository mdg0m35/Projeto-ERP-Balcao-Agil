import 'package:flutter/material.dart';
String formatDateTime(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
String formatDateOnly(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
IconData detectIconForProduct(String name) {
  final n = name.toLowerCase();
  if (n.contains('cimento') || n.contains('argamassa')) return Icons.layers;
  if (n.contains('telha')) return Icons.home;
  if (n.contains('tijolo')) return Icons.view_module;
  if (n.contains('tubo')) return Icons.plumbing;
  if (n.contains('piso')) return Icons.grid_on;
  return Icons.construction;
}
