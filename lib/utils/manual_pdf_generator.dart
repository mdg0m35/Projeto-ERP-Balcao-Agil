import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ManualPdfGenerator {
  static Future<void> generateAndDownloadManual() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.only(bottom: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Manual Ilustrado do Usuário • SaaS ERP Construção',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        build: (context) => [
          // CAPA / BANNER
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'GUIA OFICIAL ILUSTRADO PASSO A PASSO',
                  style: pw.TextStyle(
                    color: PdfColors.blue100,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Manual Visual do SaaS ERP Construção',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Aprenda como operar cada módulo no computador (Desktop) e no celular (Mobile).',
                  style:
                      const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // 1. VISÃO GERAL: DESKTOP & MOBILE
          _sectionHeader('1. Visão Geral das Telas (Desktop vs. Mobile)'),
          pw.Paragraph(
            text:
                'O SaaS ERP possui interface adaptável: no computador opera com barra lateral moderna (#0F172A) e atalhos rápidos. No celular, condensa todas as opções no Menu Hambúrguer (Drawer) com layout limpo e livre de cortes.',
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: _mockupDesktop(),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                flex: 2,
                child: _mockupMobile(),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // 2. MÓDULO PDV (BALCÃO)
          _sectionHeader('2. Módulo PDV / Balcão (Vendas e Orçamentos)'),
          _mockupPos(),
          _instructionBox(
            'Como Operar o PDV:',
            [
              '1. Na barra de pesquisa, digite o nome do item (ex: Cimento, Areia, Tijolo).',
              '2. Clique no produto ou no ícone (+) para definir a quantidade e adicionar notas (ex: "Entregar no lote 12").',
              '3. No botão verde flutuante "Orçamento", abra o carrinho de compras.',
              '4. Defina Desconto (%) ou Frete se houver.',
              '5. Clique em "Finalizar Venda" (para dar baixa imediata de estoque) ou "Salvar Orçamento".',
              '6. O sistema gera automaticamente o texto formatado para enviar no WhatsApp do cliente.',
            ],
          ),
          pw.SizedBox(height: 16),

          // 3. MÓDULO ORÇAMENTOS
          _sectionHeader('3. Módulo Orçamentos e Histórico de Vendas'),
          _mockupQuotes(),
          _instructionBox(
            'Como Operar os Orçamentos:',
            [
              '1. No topo, consulte o faturamento do dia e a quantidade de obras em andamento.',
              '2. Filtre por nome do cliente, código da venda (#) ou selecione a data no calendário.',
              '3. Use as abas: "Todos", "Em andamento", "Finalizado" ou "Cancelado".',
              '4. Toque no orçamento para expandir a lista de materiais comprados.',
              '5. Clique em "WhatsApp" para reenviar a 2ª via do recibo com chave PIX.',
              '6. Orçamentos pendentes possuem o botão verde "Aprovar / Vender" que baixa o estoque na hora.',
            ],
          ),
          pw.SizedBox(height: 16),

          // 4. MÓDULO ENTREGAS
          _sectionHeader('4. Módulo de Entregas e Carga Fracionada'),
          _mockupDeliveries(),
          _instructionBox(
            'Como Controlar Entregas no Caminhão:',
            [
              '1. Veja os pedidos que possuem remessas pendentes de envio.',
              '2. Se o cliente comprou 100 sacos de cimento e levou apenas 30, clique em "Registrar Entrega".',
              '3. Digite 30 unidades entregues; o sistema calcula e mantém 70 sacos pendentes no histórico.',
              '4. O indicador de peso (kg) auxilia o depósito a não sobrecarregar o caminhão de entrega.',
            ],
          ),
          pw.SizedBox(height: 16),

          // 5. MÓDULO ESTOQUE E NOVO PRODUTO
          _sectionHeader('5. Módulo Estoque e Cadastro de Materiais'),
          _mockupStock(),
          _instructionBox(
            'Como Gerenciar Estoque e Produtos:',
            [
              '1. Administradores podem cadastrar produtos no botão (+ Novo Produto) no topo.',
              '2. Preencha Nome, Categoria, Preço de Custo, Preço de Venda, Estoque e Peso (kg).',
              '3. Produtos com 15 unidades ou menos ativam o selo vermelho de Alerta no menu.',
              '4. Altere a quantidade física do estoque diretamente na tabela quando receber fornecedores.',
            ],
          ),
          pw.SizedBox(height: 16),

          // 6. MÓDULO EQUIPE
          _sectionHeader('6. Módulo Minha Equipe (Acessos dos Funcionários)'),
          _mockupTeam(),
          _instructionBox(
            'Como Cadastrar Funcionários:',
            [
              '1. Informe o Nome do Funcionário, E-mail de Login e uma Senha provisória (mín. 6 dígitos).',
              '2. Ao clicar em "Criar Acesso", o sistema grava o login e copia o convite formatado.',
              '3. Cole a mensagem no WhatsApp do funcionário; ele acessa com permissão restrita.',
              '4. Funcionários operam PDV, Estoque e Entregas, mas NÃO visualizam lucros nem configurações.',
            ],
          ),
          pw.SizedBox(height: 16),

          // 7. CONFIGURAÇÕES E MANUAL
          _sectionHeader('7. Configurações da Loja e Documentação'),
          _mockupSettings(),
          _instructionBox(
            'Como Personalizar sua Loja:',
            [
              '1. Clique no ícone de engrenagem no rodapé da barra lateral ou no topo do celular.',
              '2. Altere o Nome do Depósito, Nome do Administrador, Telefone/WhatsApp, Endereço e PIX.',
              '3. Escolha a Cor de Destaque: todo o sistema e a barra lateral mudarão no mesmo instante.',
              '4. O botão "Manual de Uso (PDF)" fica permanentemente salvo nesta janela para consultas futuras.',
              '5. Caso queira encerrar suas atividades, utilize o botão seguro de exclusão permanente no rodapé.',
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Manual_Ilustrado_SaaS_ERP_Construcao.pdf',
    );
  }

  static pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  static pw.Widget _instructionBox(String title, List<String> steps) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 8, bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: const pw.Border(
            left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 4),
          ...steps.map(
            (s) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(s,
                  style: const pw.TextStyle(
                      fontSize: 8.5, color: PdfColors.grey800)),
            ),
          ),
        ],
      ),
    );
  }

  // --- MOCKUPS VISUAIS EM VETOR DE CADA TELA ---

  static pw.Widget _mockupDesktop() {
    return pw.Container(
      height: 110,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 55,
            color: PdfColors.blueGrey900,
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DEPÓSITO',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold)),
                pw.Divider(color: PdfColors.grey700, height: 6),
                pw.Text('• PDV',
                    style: const pw.TextStyle(
                        color: PdfColors.blue300, fontSize: 6)),
                pw.Text('• Orçamentos',
                    style: const pw.TextStyle(
                        color: PdfColors.grey400, fontSize: 5)),
                pw.Text('• Entregas',
                    style: const pw.TextStyle(
                        color: PdfColors.grey400, fontSize: 5)),
                pw.Text('• Estoque',
                    style: const pw.TextStyle(
                        color: PdfColors.grey400, fontSize: 5)),
                pw.Text('• Equipe',
                    style: const pw.TextStyle(
                        color: PdfColors.grey400, fontSize: 5)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              color: PdfColors.grey50,
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 14,
                    color: PdfColors.white,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Painel Principal',
                            style: pw.TextStyle(
                                fontSize: 6, fontWeight: pw.FontWeight.bold)),
                        pw.Text('+ Novo Produto | Olá, Juliana',
                            style: const pw.TextStyle(
                                fontSize: 5, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    height: 12,
                    color: PdfColors.white,
                    child: pw.Text(' [🔍 Pesquisar material no depósito...] ',
                        style: const pw.TextStyle(
                            fontSize: 5, color: PdfColors.grey500)),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    color: PdfColors.white,
                    child: pw.Text(
                        'Cimento CP-II 50kg • R\$ 34,90 (Em Estoque: 250 sc)',
                        style: const pw.TextStyle(fontSize: 5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _mockupMobile() {
    return pw.Container(
      height: 110,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            height: 16,
            color: PdfColors.blueGrey900,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('☰  PDV / Balcão',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('⚙  [+] ',
                    style: const pw.TextStyle(
                        color: PdfColors.white, fontSize: 6)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('🔍 Buscar item...',
                      style: const pw.TextStyle(
                          fontSize: 5, color: PdfColors.grey600)),
                  pw.Divider(height: 4),
                  pw.Text('• Tijolo 8 Furos - R\$ 1,20',
                      style: const pw.TextStyle(fontSize: 5)),
                  pw.Text('• Areia Lavada m³ - R\$ 130,00',
                      style: const pw.TextStyle(fontSize: 5)),
                  pw.Spacer(),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(3),
                    color: PdfColors.green700,
                    child: pw.Text('Orçamento (2) • R\$ 131,20',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 5,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _mockupPos() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MOCKUP DE TELA: PDV & BALCÃO',
              style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            color: PdfColors.grey100,
            child: pw.Text('🔍 Pesquisar material...',
                style:
                    const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('1. Tubo Soldável 25mm 6m (Tigre) • R\$ 24,50',
                  style: const pw.TextStyle(fontSize: 7)),
              pw.Text('[ + Adicionar ]',
                  style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800)),
            ],
          ),
          pw.Divider(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('2. Argamassa AC-II 20kg • R\$ 18,90',
                  style: const pw.TextStyle(fontSize: 7)),
              pw.Text('[ + Adicionar ]',
                  style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _mockupQuotes() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MOCKUP DE TELA: ORÇAMENTOS E VENDAS',
              style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Faturamento do Dia: R\$ 4.850,00',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800)),
              pw.Text('Em Andamento: 3 obras',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800)),
            ],
          ),
          pw.Divider(height: 6),
          pw.Text(
              'Cliente: Marcos Roberto • Total: R\$ 890,00 [Status: Em andamento]',
              style: const pw.TextStyle(fontSize: 7)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('[ Reenviar WhatsApp ]   ',
                  style: const pw.TextStyle(
                      fontSize: 6, color: PdfColors.blue700)),
              pw.Text('[ Aprovar / Vender ]',
                  style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _mockupDeliveries() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MOCKUP DE TELA: CONTROLE DE CARGA & ENTREGAS',
              style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text('Obra: Residencial Parque das Flores • Peso Carga: 2.450 kg',
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              '• Cimento CP-II: 50 sacos comprados | 20 entregues | 30 pendentes',
              style: const pw.TextStyle(fontSize: 7)),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('[ Registrar Entrega Parcial ]',
                style: pw.TextStyle(
                    fontSize: 6,
                    color: PdfColors.blue800,
                    fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _mockupStock() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MOCKUP DE TELA: CONTROLE DE ESTOQUE',
              style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Material',
                  style: pw.TextStyle(
                      fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.Text('Custo',
                  style: pw.TextStyle(
                      fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.Text('Venda',
                  style: pw.TextStyle(
                      fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.Text('Qtd. Estoque',
                  style: pw.TextStyle(
                      fontSize: 7, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Divider(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Barra Ferro 3/8 12m',
                  style: const pw.TextStyle(fontSize: 7)),
              pw.Text('R\$ 32,00', style: const pw.TextStyle(fontSize: 7)),
              pw.Text('R\$ 48,00', style: const pw.TextStyle(fontSize: 7)),
              pw.Text('12 barras ⚠️ (Baixo)',
                  style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.red800,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _mockupTeam() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MOCKUP DE TELA: GESTÃO DE EQUIPE',
              style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(
              'Novo Funcionário: [ Nome: Carlos Eduardo | E-mail: carlos@loja.com ]',
              style: const pw.TextStyle(fontSize: 7)),
          pw.SizedBox(height: 2),
          pw.Text(
              'Acesso Copiado: "Olá Carlos! Acesse seu sistema no link: https://... com a senha: ***"',
              style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static pw.Widget _mockupSettings() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MOCKUP DE TELA: CONFIGURAÇÕES',
              style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text('• Nome da Loja: Madereira Juliana',
              style: const pw.TextStyle(fontSize: 7)),
          pw.Text('• Cores de Tema: [Azul] [Laranja] [Verde] [Roxo] [Vermelho]',
              style: const pw.TextStyle(fontSize: 7)),
          pw.Text('• [📄 Manual de Uso do Sistema (PDF) - Baixar]',
              style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.orange900,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
