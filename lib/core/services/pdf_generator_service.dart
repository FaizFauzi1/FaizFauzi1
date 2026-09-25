import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class PdfGeneratorService {
  static final PdfGeneratorService _instance = PdfGeneratorService._internal();

  factory PdfGeneratorService() {
    return _instance;
  }

  PdfGeneratorService._internal();

  Future<void> generateAndShareInvoice(Booking booking, Vendor vendor, String serviceName, double amount) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildInvoiceLayout(booking, vendor, serviceName, amount);
        },
      ),
    );

    await _saveAndShareFile(pdf, 'invoice_${booking.id}.pdf');
  }

  Future<void> generateAndShareContract(Booking booking, Vendor vendor, String serviceName, double amount) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildContractLayout(booking, vendor, serviceName, amount);
        },
      ),
    );

    await _saveAndShareFile(pdf, 'contract_${booking.id}.pdf');
  }

  Future<void> generateAndShareQuotation(VendorServiceEnhanced service, Vendor vendor) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildQuotationLayout(service, vendor);
        },
      ),
    );

    await _saveAndShareFile(pdf, 'quotation_${service.id}.pdf');
  }

  pw.Widget _buildInvoiceLayout(Booking booking, Vendor vendor, String serviceName, double amount) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('EventEase', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('From:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(vendor.name),
                pw.Text(vendor.location),
                pw.Text(vendor.contactInfo['email'] ?? ''),
                pw.Text(vendor.contactInfo['phone'] ?? ''),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Customer ID: ${booking.customerId}'), // Ideally Customer Name
                pw.Text('Booking ID: ${booking.id}'),
                pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Table.fromTextArray(
          headers: ['Description', 'Date', 'Amount'],
          data: [
            [serviceName, DateFormat('yyyy-MM-dd').format(booking.bookingDate), 'RM ${amount.toStringAsFixed(2)}'],
          ],
          border: null,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight,
          },
        ),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Subtotal: RM ${amount.toStringAsFixed(2)}'),
                pw.Text('Service Fee (5%): RM ${(amount * 0.05).toStringAsFixed(2)}'),
                pw.Text('Tax (6%): RM ${(amount * 0.06).toStringAsFixed(2)}'),
                pw.SizedBox(height: 4),
                pw.Text('Total: RM ${(amount * 1.11).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
        pw.Spacer(),
        pw.Footer(
          leading: pw.Text('Thank you for your business!'),
          trailing: pw.Text('Generated via EventEase'),
        ),
      ],
    );
  }

  pw.Widget _buildContractLayout(Booking booking, Vendor vendor, String serviceName, double amount) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 0,
          child: pw.Center(child: pw.Text('SERVICE AGREEMENT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        ),
        pw.SizedBox(height: 20),
        pw.Paragraph(text: 'This Agreement is made on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}, between:'),
        pw.Paragraph(text: 'Service Provider: ${vendor.name} ("Vendor")'),
        pw.Paragraph(text: 'AND'),
        pw.Paragraph(text: 'Client (Customer ID: ${booking.customerId}) ("Client")'),
        pw.SizedBox(height: 10),
        pw.Header(level: 1, text: '1. Services'),
        pw.Paragraph(text: 'The Vendor agrees to provide the following services: $serviceName on ${DateFormat('yyyy-MM-dd').format(booking.bookingDate)}.'),
        pw.SizedBox(height: 10),
        pw.Header(level: 1, text: '2. Payment'),
        pw.Paragraph(text: 'The total fee for the services is RM ${(amount * 1.11).toStringAsFixed(2)}. Payment has been processed via EventEase.'),
        pw.SizedBox(height: 10),
        pw.Header(level: 1, text: '3. Cancellation Policy'),
        pw.Paragraph(text: 'Cancellations must be made in accordance with the Vendor\'s cancellation policy listed on EventEase.'),
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 150, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text('Vendor Signature'),
                pw.Text(vendor.name),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 150, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text('Client Signature'),
                pw.Text('(Digitally Signed via EventEase)'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildQuotationLayout(VendorServiceEnhanced service, Vendor vendor) {
     return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('QUOTATION', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('EventEase', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('From:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(vendor.name),
            pw.Text(vendor.location),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Table.fromTextArray(
          headers: ['Item', 'Description', 'Price'],
          data: [
            [service.name, service.description, 'RM ${service.price.toStringAsFixed(2)}'],
          ],
          border: null,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 20),
        pw.Paragraph(text: 'Note: This quotation is valid for 14 days from the date of issue.'),
      ],
    );
  }


  Future<void> _saveAndShareFile(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final xFile = XFile.fromData(
      bytes,
      name: filename,
      mimeType: 'application/pdf',
    );
    await Share.shareXFiles([xFile], text: 'Here is your document from EventEase');
  }
}
