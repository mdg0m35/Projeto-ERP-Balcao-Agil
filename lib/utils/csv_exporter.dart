import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/models.dart';

class CsvExporter {
  static void downloadProductsCsv(List<Product> products, String storeName) {
    final buffer = StringBuffer();
    // Cabeçalho compatível com o Excel (formato CSV brasileiro com ponto e vírgula)
    buffer.writeln(
        'ID;Nome do Produto;Categoria;Preco Custo;Preco Venda;Estoque;Unidade;Peso (kg)');

    for (final p in products) {
      buffer.writeln(
        '${p.id};"${p.name.replaceAll('"', '""')}";"${p.category}";'
        '${p.costPrice.toStringAsFixed(2).replaceAll('.', ',')};'
        '${p.price.toStringAsFixed(2).replaceAll('.', ',')};'
        '${p.stock};${p.unit};${p.weightKg.toStringAsFixed(2).replaceAll('.', ',')}',
      );
    }

    _downloadFile(
        buffer.toString(), 'produtos_${_sanitizeFilename(storeName)}.csv');
  }

  static void downloadQuotesCsv(List<SavedQuote> quotes, String storeName) {
    final buffer = StringBuffer();
    buffer.writeln(
        'ID;Data;Cliente;Telefone;Endereco;Status;Desconto (%);Frete;Total (R\$);Itens');

    for (final q in quotes) {
      final itemsSummary =
          q.items.map((i) => '${i.quantity}x ${i.product.name}').join(' | ');
      final dateFormatted =
          '${q.createdAt.day.toString().padLeft(2, '0')}/${q.createdAt.month.toString().padLeft(2, '0')}/${q.createdAt.year}';

      buffer.writeln(
        '${q.id};$dateFormatted;"${q.clientName.replaceAll('"', '""')}";"${q.clientPhone}";'
        '"${q.address.replaceAll('"', '""')}";${q.status};'
        '${q.discountPercent.toStringAsFixed(1).replaceAll('.', ',')};'
        '${q.deliveryFee.toStringAsFixed(2).replaceAll('.', ',')};'
        '${q.finalTotal.toStringAsFixed(2).replaceAll('.', ',')};'
        '"$itemsSummary"',
      );
    }

    _downloadFile(buffer.toString(),
        'pedidos_orcamentos_${_sanitizeFilename(storeName)}.csv');
  }

  static void _downloadFile(String content, String filename) {
    // Adiciona o prefixo BOM (\uFEFF) para que o Excel abra acentos em português perfeitamente
    final bytes = utf8.encode('\uFEFF$content');
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static String _sanitizeFilename(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  }
}
