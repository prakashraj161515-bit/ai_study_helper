import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFService {
  Future<void> generateMarksheet(int score, int total, String topic) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('AI Study Helper - Marksheet', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text('Topic: $topic', style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 10),
                pw.Text('Score: $score / $total', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
                pw.Text('Percentage: ${(score / total * 100).toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 40),
                pw.Text('Generated on: ${DateTime.now().toString()}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              ],
            ),
          );
        },
      ),
    );

    // Printing.layoutPdf works on Web without dart:io
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
