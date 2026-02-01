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
    
    // STRATEGY: Linear Split (O(N)) to prevent backtracking hangs.
    // Anchored by "UPI Transaction ID".
    // 
    // We use a simplified delimiter to ensure we successfully split.
    // We handle whitespace/case in the regex.
    final delimiter = RegExp(r'UPI\s+Transaction\s+ID\s*:\s*', caseSensitive: false);
    final chunks = text.split(delimiter);

    print("DEBUG: Split text into ${chunks.length} chunks.");

    if (chunks.length <= 1) {
      print("DEBUG: No UPI Transaction IDs found via Split.");
      return [];
    }

    // Regexes
    final idRegex = RegExp(r'(\d+)');
    final amountRegex = RegExp(r'(?:₹|Rs\.?|INR)\s*([\d,]+(?:\.\d{2})?)', caseSensitive: false);
    
    // Date: 09\nOct,\n2025 \n 08:33\nAM
    // Regex matches the components, handling standard whitespace/newlines/separators.
    // Normalized to be Case Insensitive for AM/PM
    final dateRegex = RegExp(r'(\d{1,2})[\s\-\/\n]+([A-Za-z]{3})[\s\-\/,\n]+(\d{4})[\s\n]+(\d{2}:\d{2}[\s\n\r]+[APap][Mm])');
    
    // Name: Paid to\nRahul
    // Added case insensitive to Name regex too
    final nameRegex = RegExp(r'(Paid\s+to|Received\s+from)[\s\n]+([A-Za-z0-9\s\.\-\&\@]+)', caseSensitive: false);

    for (int i = 1; i < chunks.length; i++) {
       try {
         final currentChunk = chunks[i]; 
         final previousChunk = chunks[i-1];

         // --- 1. ID (Current Chunk Head) ---
         final chunkHead = currentChunk.length > 50 ? currentChunk.substring(0, 50) : currentChunk;
         final idMatch = idRegex.firstMatch(chunkHead);
         if (idMatch == null) continue;
         final txId = idMatch.group(1)!;

         // --- 2. AMOUNT (Current Chunk Head/Body) ---
         final amountMatch = amountRegex.firstMatch(currentChunk);
         if (amountMatch == null) {
            print("Skipping Tx $txId: Amount not found.");
            continue;
         }
         final amountStr = amountMatch.group(1)!.replaceAll(RegExp(r'[\n\r\s,]'), ''); 

         // --- 3. NAME & DATE (Previous Chunk Tail) ---
         // Increase lookback to 1000 chars to cover large headers or page breaks
         final prevTail = previousChunk.length > 1000 
            ? previousChunk.substring(previousChunk.length - 1000) 
            : previousChunk;
            
         // Find LAST Name
         final nameMatches = nameRegex.allMatches(prevTail);
         if (nameMatches.isEmpty) {
             print("Skipping Tx $txId: Name pattern not found in prev chunk.");
             continue;
         }
         final nameMatch = nameMatches.last;
         final typeStr = nameMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
         final nameRaw = nameMatch.group(2)!;

         // Check Date logic
         // We look for Date in the whole tail. The relevant date is the one closest to the Name.
         // Usually Date appears before Name.
         final dateMatches = dateRegex.allMatches(prevTail);
         if (dateMatches.isEmpty) {
             print("Skipping Tx $txId: Date not found in prev chunk.");
             continue;
         }
         
         // Use the last date match found (closest to end of chunk / start of next transaction)
         final dateMatch = dateMatches.last;
         
         final day = dateMatch.group(1)!;
         final month = dateMatch.group(2)!;
         final year = dateMatch.group(3)!;
         // Clean TIME: Replace all whitespace/newlines/carriage-returns with single space
         // Handles 08:33\r\nAM -> 08:33 AM
         final time = dateMatch.group(4)!.replaceAll(RegExp(r'\s+'), ' ').toUpperCase(); 
         
         final cleanDateStr = "$day $month, $year $time"; 

         // Parsing
         final name = nameRaw.replaceAll('\n', ' ').trim();
         final bool isCredit = typeStr.toLowerCase().contains('received');

         final dateFormat = DateFormat("d MMM, yyyy hh:mm a");
         DateTime date;
         try {
            date = dateFormat.parse(cleanDateStr);
         } catch (e) {
            print("Date parse failed for '$cleanDateStr', using now()");
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
         print("Error parsing chunk $i: $e");
       }
    }

    return transactions;
  }
}
