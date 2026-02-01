import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class PdfParserService {
  // Regex to match the transaction block across multiple lines.
  // Format detected:
  // Paid to / Received from [Name]
  // UPI Transaction ID: [ID]
  // No global regex needed anymore, we use split strategy.


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
    
    // FINAL ROBUST REGEX STRATEGY
    // We use a single complex regex with "Negative Lookaheads" to prevent bleeding.
    // 
    // 1. (Paid to|...) : Type
    // 2. Name: ((?:(?!UPI\s+Transaction).)*?) -> Match anything UNTIL we see "UPI Transaction".
    //    This prevents the name capture from jumping over an ID if the start is messy.
    // 3. ID: (\d+)
    // 4. Amount: (?:₹|Rs\.?|INR)\s*([\d,]+) -> Relaxed symbol
    // 5. Date: (\d{1,2} [A-Za-z]{3}...) -> Relaxed date (1 or 2 digits)
    
    final RegExp robustRegex = RegExp(
      r'(Paid\s+to|Received\s+from)\s+' // Group 1: Type
      r'((?:(?!UPI\s+Transaction\s+ID).)*?)\s+' // Group 2: Name (Lazy, stops before Next ID)
      r'UPI\s+Transaction\s+ID:\s+(\d+)' // Group 3: ID
      r'.*?' // Skip "Paid by..." junk
      r'(?:₹|Rs\.?|INR)\s*([\d,]+)' // Group 4: Amount
      r'.*?' // Skip junk
      r'(\d{1,2}[\s\-\/]+[A-Za-z]{3}[\s\-\/]+\d{4}\s+\d{2}:\d{2}\s+[AP]M)', // Group 5: Date
      dotAll: true, 
      caseSensitive: false,
    );

    final matches = robustRegex.allMatches(text);
    print("DEBUG: Found ${matches.length} matches via Regex");

    for (var match in matches) {
      try {
        final typeStr = match.group(1)!;
        final nameRaw = match.group(2)!;
        final txId = match.group(3)!;
        final amountStr = match.group(4)!.replaceAll(',', '');
        final dateStr = match.group(5)!;

        // Clean up Name
        final name = nameRaw.replaceAll('\n', ' ').trim();
        final bool isCredit = typeStr.toLowerCase().contains('received');

        // Parse Date with Normalization
        String cleanDateStr = dateStr.replaceAll(RegExp(r'[\s\-\/]+'), ' ').trim(); 
        
        // Fix missing comma for "d MMM, yyyy" format expectation
        if (!cleanDateStr.contains(',')) {
           cleanDateStr = cleanDateStr.replaceAllMapped(
             RegExp(r'(\d{1,2}\s+[A-Za-z]{3})\s+(\d{4})'), 
             (m) => '${m.group(1)}, ${m.group(2)}'
           );
        }

        final dateFormat = DateFormat("d MMM, yyyy hh:mm a");
        DateTime date;
        try {
           date = dateFormat.parse(cleanDateStr);
        } catch (e) {
           print("Date parse failed for '$cleanDateStr', fallback to current time");
           date = DateTime.now(); 
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
