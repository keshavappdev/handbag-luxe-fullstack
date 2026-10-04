import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/invoice_data.dart';
import '../../models/order_summary.dart';
import '../../services/api/order_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxury_widgets.dart';

/// Shows the server-rendered invoice (same HTML the website/old app show)
/// on screen in an embedded WebView, but DOWNLOAD/SHARE build a separate,
/// native PDF from get_invoice_data — structured data computed with the
/// exact same GST/tax-breakdown and totals arithmetic as the on-screen
/// page (see OrderService.getInvoiceData), so the numbers match exactly
/// instead of being a simplified reconstruction. Converting the on-screen
/// HTML itself to PDF was tried first (Printing.convertHtml) but proved
/// unreliable: that HTML is the ADMIN dashboard's own invoice template,
/// dragging in that panel's interactive chrome which isn't relevant
/// standalone and could stall the conversion indefinitely even with every
/// <script> tag stripped first. Building the PDF natively from the same
/// underlying figures sidesteps that HTML entirely.
class InvoiceView extends StatefulWidget {
  const InvoiceView({super.key, required this.order});
  final OrderSummary order;

  @override
  State<InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<InvoiceView> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  bool _exporting = false;
  InvoiceData? _invoiceData;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        Get.find<OrderService>().getInvoiceHtml(widget.order.id),
        Get.find<OrderService>().getInvoiceData(widget.order.id),
      ]);
      if (!mounted) return;
      await _controller.loadHtmlString(results[0] as String);
      if (!mounted) return;
      setState(() {
        _invoiceData = results[1] as InvoiceData?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the invoice: $e';
      });
    }
  }

  Future<Uint8List> _buildPdf(InvoiceData invoice) async {
    // Noto Sans (bundled via printing's Google Fonts helper, cached after
    // first download) actually has a ₹ glyph — the PDF package's default
    // core font doesn't, which would otherwise silently render it as a
    // missing-character box.
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final doc = pw.Document();
    final currency = invoice.currency.isEmpty ? 'Rs.' : invoice.currency;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(fontSize: 20, font: boldFont),
              ),
              pw.Text(
                invoice.invoiceNo,
                style: pw.TextStyle(fontSize: 11, font: boldFont),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Order #${invoice.orderId}  •  ${invoice.orderDate}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _partyBlock(
                  'SOLD BY',
                  invoice.soldBy,
                  boldFont,
                  isSoldBy: true,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _partyBlock('BILL TO', invoice.billTo, boldFont),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Payment method: ${invoice.paymentMethod}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3.2),
              1: pw.FlexColumnWidth(1.4),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(1.3),
              4: pw.FlexColumnWidth(1.6),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('ITEM', boldFont),
                  _cell('PRICE', boldFont),
                  _cell('TAX', boldFont),
                  _cell('QTY', boldFont),
                  _cell('SUBTOTAL', boldFont),
                ],
              ),
              for (final item in invoice.items)
                pw.TableRow(
                  children: [
                    _cell(
                      item.variant.isEmpty
                          ? item.name
                          : '${item.name}\n${item.variant}',
                      regularFont,
                    ),
                    _cell(
                      '$currency ${item.priceExclTax.toStringAsFixed(2)}',
                      regularFont,
                    ),
                    _cell(
                      item.taxBreakdown.isEmpty
                          ? '—'
                          : item.taxBreakdown
                                .map(
                                  (t) =>
                                      '${t.title} ${t.percentage.toStringAsFixed(1)}%: $currency ${t.amount.toStringAsFixed(2)}',
                                )
                                .join('\n'),
                      regularFont,
                    ),
                    _cell('${item.quantity}', regularFont),
                    _cell(
                      '$currency ${item.subtotal.toStringAsFixed(2)}',
                      regularFont,
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _totalRow(
                  'Total Order Price',
                  invoice.orderTotal,
                  currency,
                  regularFont,
                ),
                _totalRow(
                  'Delivery Charge',
                  invoice.deliveryCharge,
                  currency,
                  regularFont,
                  freeLabel: invoice.deliveryCharge == 0,
                ),
                if (invoice.walletBalance > 0)
                  _totalRow(
                    'Wallet Used',
                    -invoice.walletBalance,
                    currency,
                    regularFont,
                  ),
                if (invoice.promoCode != null)
                  _totalRow(
                    'Promo (${invoice.promoCode}) Discount',
                    -invoice.promoDiscount,
                    currency,
                    regularFont,
                  ),
                if (invoice.specialDiscountAmount > 0)
                  _totalRow(
                    'Special Discount (${invoice.specialDiscountPercent.toStringAsFixed(0)}%)',
                    -invoice.specialDiscountAmount,
                    currency,
                    regularFont,
                  ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 220,
                  height: 0.75,
                  color: PdfColors.grey600,
                ),
                pw.SizedBox(height: 6),
                _totalRow(
                  'Final Total',
                  invoice.finalTotal,
                  currency,
                  boldFont,
                  bold: true,
                ),
                if (invoice.totalPayableCod != null)
                  _totalRow(
                    'Total Payable on COD',
                    invoice.totalPayableCod!,
                    currency,
                    boldFont,
                    bold: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _partyBlock(
    String label,
    InvoiceParty party,
    pw.Font boldFont, {
    bool isSoldBy = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            font: boldFont,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(party.name, style: pw.TextStyle(fontSize: 11, font: boldFont)),
        if (party.address.isNotEmpty)
          pw.Text(party.address, style: const pw.TextStyle(fontSize: 9)),
        if (party.state.isNotEmpty)
          pw.Text(
            'State: ${party.state}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        if (party.mobile.isNotEmpty)
          pw.Text(
            'Mobile: ${party.mobile}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        if (party.email.isNotEmpty)
          pw.Text(party.email, style: const pw.TextStyle(fontSize: 9)),
        if (isSoldBy && party.taxName.isNotEmpty && party.taxNumber.isNotEmpty)
          pw.Text(
            '${party.taxName}: ${party.taxNumber}',
            style: const pw.TextStyle(fontSize: 9),
          ),
      ],
    );
  }

  pw.Widget _cell(String text, pw.Font font) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: pw.TextStyle(fontSize: 8.5, font: font)),
  );

  pw.Widget _totalRow(
    String label,
    double amount,
    String currency,
    pw.Font font, {
    bool bold = false,
    bool freeLabel = false,
  }) {
    final negative = amount < 0;
    final display = freeLabel
        ? 'Free'
        : '${negative ? '- ' : ''}$currency ${amount.abs().toStringAsFixed(2)}';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: bold ? 11 : 9, font: font),
            ),
          ),
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              display,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: bold ? 11 : 9, font: font),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _renderPdf() async {
    final invoice = _invoiceData;
    if (invoice == null) {
      Get.rawSnackbar(
        message:
            'Invoice details are still loading — please try again in a moment.',
      );
      return null;
    }
    setState(() => _exporting = true);
    try {
      return await _buildPdf(invoice);
    } catch (e) {
      if (mounted) {
        Get.rawSnackbar(message: 'Could not generate the PDF: $e');
      }
      return null;
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _download() async {
    final bytes = await _renderPdf();
    if (bytes == null || !mounted) return;
    // Opens the native print/preview screen, which itself offers Save/Print
    // as system actions — the OS handles the actual file write, so this
    // needs no storage permission or manual file-path handling.
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'invoice_${widget.order.id}.pdf',
    );
  }

  Future<void> _share() async {
    final bytes = await _renderPdf();
    if (bytes == null || !mounted) return;
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'invoice_${widget.order.id}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const Center(child: CircularProgressIndicator()),
              ],
            ),
      bottomNavigationBar: (_loading || _error != null)
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: KColors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _exporting ? null : _download,
                        child: const Text('DOWNLOAD PDF'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _exporting ? null : _share,
                        style: FilledButton.styleFrom(
                          backgroundColor: KColors.black,
                        ),
                        child: _exporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: KColors.white,
                                ),
                              )
                            : const Text('SHARE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
