import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('Dump PDF Text', () async {
    final file = File('sample.pdf');
    if (!file.existsSync()) {
      print('SAMPLE PDF NOT FOUND AT ${file.absolute.path}');
      return;
    }

    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();

    print('\n--- RAW PDF TEXT START ---');
    print(text);
    print('--- RAW PDF TEXT END ---\n');
    
    // Also try splitting to see what happens
    final delimiter = RegExp(r'UPI\s+Transaction\s+ID\s*:\s*', caseSensitive: false);
    final chunks = text.split(delimiter);
    print('Split count: ${chunks.length}');
  });
}
