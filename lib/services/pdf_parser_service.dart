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
    
    // Date: 09\nOct,\n2025 ...
    // Needs to handle newlines between parts.
    final dateRegex = RegExp(r'(\d{1,2})[\s\-\/\n]+([A-Za-z]{3})[\s\-\/,\n]+(\d{4})[\s\n]+(\d{2}:\d{2}[\s\n]+[AP]M)');
    
    // Name: Paid to\nRahul
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
         // Amount comes after ID.
         final amountMatch = amountRegex.firstMatch(currentChunk);
         if (amountMatch == null) {
            print("Skipping Tx $txId: Amount not found.");
            continue;
         }
         final amountStr = amountMatch.group(1)!.replaceAll(RegExp(r'[\n\r\s,]'), ''); // Remove newlines/commas

         // --- 3. NAME (Previous Chunk Tail) ---
         // Logic: The name is immediately before the "UPI Transaction ID" split.
         // Look at the last portion of prev chunk.
         final prevTail = previousChunk.length > 600 
            ? previousChunk.substring(previousChunk.length - 600) 
            : previousChunk;
            
         final nameMatches = nameRegex.allMatches(prevTail);
         if (nameMatches.isEmpty) {
             print("Skipping Tx $txId: Name pattern not found in prev chunk.");
             continue;
         }
         // The matches are in order. The one relating to *this* ID is the LAST one in the chunk.
         final nameMatch = nameMatches.last;
         final typeStr = nameMatch.group(1)!.replaceAll('\n', ' ');
         final nameRaw = nameMatch.group(2)!;

         // --- 4. DATE (Previous Chunk Tail) ---
         // Date appears BEFORE Name.
         // 01 Oct ... Paid to ... UPI ID
         // So in prevTail, we should find the Date.
         // It should be the Last date match in the chunk (closest to the Name/ID).
         final dateMatches = dateRegex.allMatches(prevTail);
         if (dateMatches.isEmpty) {
             print("Skipping Tx $txId: Date not found in prev chunk.");
             continue;
         }
         final dateMatch = dateMatches.last;
         
         // Reconstruct Date String from groups because of newlines
         // Group 1: Day, 2: Month, 3: Year, 4: Time
         final day = dateMatch.group(1)!;
         final month = dateMatch.group(2)!;
         final year = dateMatch.group(3)!;
         final time = dateMatch.group(4)!.replaceAll('\n', ' '); // 08:33 AM
         
         final cleanDateStr = "$day $month, $year $time"; // "01 Oct, 2025 08:33 AM"

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
