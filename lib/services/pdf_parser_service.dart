import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class PdfParserService {
  // Regex to match the transaction block across multiple lines.
  // Format detected:
  // Paid to / Received from [Name]
  // UPI Transaction ID: [ID]
  // Paid by...
  // ₹[Amount]
  // [Date]
  final RegExp _transactionRegex = RegExp(
    r'(Paid\s+to|Received\s+from)\s+(.*?)\s+UPI\s+Transaction\s+ID:\s+(\d+)\s+(Paid\s+by|Paid\s+to)\s+(.*?)\s+₹([\d,]+)\s+(\d{2}\s+[A-Za-z]{3},\s+\d{4}\s+\d{2}:\d{2}\s+[AP]M)',
    dotAll: true,
    caseSensitive: false,
  );

  Future<List<TransactionModel>> pickAndParsePdf() async {
    print("DEBUG: pickAndParsePdf called");
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Crucial for Web & Mobile to get bytes
      );
      print("DEBUG: FilePicker returned: ${result != null}");
      
      if (result != null) {
        final platformFile = result.files.single;
        final bytes = platformFile.bytes;

        if (bytes != null) {
          try {
            print("DEBUG: Parsing bytes (Size: ${bytes.length})...");
            final PdfDocument document = PdfDocument(inputBytes: bytes);
            
            print("DEBUG: Extracting text...");
            String text = PdfTextExtractor(document).extractText();
            document.dispose();
            
            print("DEBUG: Text extracted, length: ${text.length}");
            return _parseText(text);
          } catch (e) {
             print("Error parsing PDF bytes: $e");
             return [];
          }
        } else {
             print("ERROR: FilePicker returned null bytes despite withData: true");
             // On some rare mobile devices with large files, this might happen. 
             // But for statements, it should be fine.
             return [];
        }
      }
    } catch (e) {
      print("DEBUG: CRITICAL ERROR in Picker: $e");
    }
    return [];
  }

  List<TransactionModel> _parseText(String text) {
    List<TransactionModel> transactions = [];
    
    final matches = _transactionRegex.allMatches(text);

    for (var match in matches) {
      try {
        final typeStr = match.group(1)!; // Paid to / Received from
        final nameRaw = match.group(2)!; // Name
        final txId = match.group(3)!;
        final amountStr = match.group(6)!.replaceAll(',', '');
        final dateStr = match.group(7)!;

        // Clean up Name (remove newlines usually present in PDF text extraction)
        final name = nameRaw.replaceAll('\n', ' ').trim();
        
        final bool isCredit = typeStr.toLowerCase().contains('received');

        // Parse Date: "09 Oct, 2025 01:06 PM"
        // Parse Date: "09 Oct, 2025 01:06 PM"
        final dateFormat = DateFormat("dd MMM, yyyy hh:mm a");
        final cleanDateStr = dateStr.replaceAll(RegExp(r'\s+'), ' ').trim();
        print("DEBUG: Parsing date: '$cleanDateStr'");
        
        DateTime date;
        try {
           date = dateFormat.parse(cleanDateStr);
        } catch (e) {
           print("DEBUG: Date parse failed for '$cleanDateStr'");
           // Try one more format if needed or rethrow
           rethrow;
        }
        
        String sender = isCredit ? name : "Self";
        String receiver = isCredit ? "Self" : name;
        
        final tx = TransactionModel(
          id: txId,
          date: date,
          amount: double.parse(amountStr),
          description: "$typeStr $name",
          sender: sender,
          receiver: receiver,
          isCredit: isCredit,
        );
        
        transactions.add(tx);
      } catch (e) {
        print("Error parsing match: $e");
      }
    }

    return transactions;
  }
}
