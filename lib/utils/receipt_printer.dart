import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order.dart';

class ReceiptPrinter {
  static Future<void> printReceipt(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  "DinO Dine",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "Restaurant POS System",
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),

              // Order Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Order #${order.id.substring(0, 6)}"),
                  pw.Text("Table ${order.tableNo}"),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text("Date: ${_formatDate(order.createdAt)}"),
              pw.Divider(),

              // Items
              pw.SizedBox(height: 5),
              pw.Text(
                "ITEMS",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              ...order.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text("${item.quantity}x ${item.name}"),
                      ),
                      pw.Text("TL ${item.total.toStringAsFixed(2)}"),
                    ],
                  ),
                );
              }),
              pw.Divider(),

              // Totals
              pw.SizedBox(height: 5),
              _buildTotalRow(context, "Subtotal", order.subtotal),
              _buildTotalRow(context, "Tax (15%)", order.tax),
              _buildTotalRow(context, "Service (5%)", order.serviceCharge),
              if (order.discount > 0)
                _buildTotalRow(context, "Discount", -order.discount),
              pw.Divider(),
              _buildTotalRow(context, "TOTAL", order.total, isBold: true),

              // Payment Method
              if (order.paymentMethod != null) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  "Payment: ${order.paymentMethod.toString().split('.').last.toUpperCase()}",
                ),
              ],

              pw.SizedBox(height: 20),

              // Footer
              pw.Center(
                child: pw.Text(
                  "Thank You!",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "Please visit again",
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  "Powered by DinO Dine POS",
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildTotalRow(
    pw.Context context,
    String label,
    double amount, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            "TL ${amount.toStringAsFixed(2)}",
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return "N/A";
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // Print kitchen order ticket
  static Future<void> printKitchenTicket(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Kitchen Header
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    "KITCHEN ORDER",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // Order Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "ORDER #${order.id.substring(0, 6)}",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Table ${order.tableNo}",
                    style: pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text("Time: ${_formatDate(DateTime.now())}"),
              pw.Divider(thickness: 2),

              // Items
              pw.SizedBox(height: 10),
              ...order.items.map((item) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 30,
                        child: pw.Text(
                          "${item.quantity}x",
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          item.name,
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),

              // Special instructions
              if (order.items.any(
                (item) =>
                    item.specialInstructions != null &&
                    item.specialInstructions!.isNotEmpty,
              ))
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "SPECIAL INSTRUCTIONS:",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    ...order.items
                        .where(
                          (item) =>
                              item.specialInstructions != null &&
                              item.specialInstructions!.isNotEmpty,
                        )
                        .map(
                          (item) => pw.Text("- ${item.specialInstructions}"),
                        ),
                  ],
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
