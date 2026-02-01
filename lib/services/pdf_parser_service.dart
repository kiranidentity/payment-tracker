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

    // Regexes for looking INSIDE a chunk
    // 1. ID: The first sequence of digits in the chunk.
    final idRegex = RegExp(r'(\d+)');
    
    // 2. Amount: (₹|Rs|INR) ... digits
    final amountRegex = RegExp(r'(?:₹|Rs\.?|INR)\s*([\d,]+(?:\.\d{2})?)', caseSensitive: false);
    
    // 3. Date: Flexible (1-2 digits, 3 chars Month, 4 digits Year)
    final dateRegex = RegExp(r'(\d{1,2}[\s\-\/]+[A-Za-z]{3}[\s\-\/]+\d{4}\s+\d{2}:\d{2}\s+[AP]M)');

    // 4. Name: Look at the TAIL of the PREVIOUS chunk.
    //    Find the LAST "Paid to/Received from" + Name.
    final namePattern = RegExp(r'(Paid\s+to|Received\s+from)\s+([A-Za-z0-9\s\.\-\&\@]+)', caseSensitive: false);

    // We start at i=1. Chunk 0 is the prologue (before first ID).
    // chunks[i] contains ID, Amount, Date for Tx[i].
    // chunks[i-1] contains the Name for Tx[i] (at its end).
    for (int i = 1; i < chunks.length; i++) {
       try {
         final currentChunk = chunks[i]; // No trim yet, keep raw for safety
         final previousChunk = chunks[i-1];

         // --- 1. ID ---
         // ID must be at the very start of the chunk.
         // But allow some noise just in case.
         // Take the first 50 chars to look for ID.
         final chunkHead = currentChunk.length > 50 ? currentChunk.substring(0, 50) : currentChunk;
         final idMatch = idRegex.firstMatch(chunkHead);
         if (idMatch == null) {
            print("Skipping Chunk $i: No ID found in head.");
            continue;
         }
         final txId = idMatch.group(1)!;

         // --- 2. AMOUNT ---
         // Search mostly in the first half of the chunk to avoid confusion with footer?
         // Usually amount is near the top.
         final amountMatch = amountRegex.firstMatch(currentChunk);
         if (amountMatch == null) {
            print("Skipping Tx $txId: Amount not found. Chunk len: ${currentChunk.length}");
            continue;
         }
         final amountStr = amountMatch.group(1)!.replaceAll(',', '');

         // --- 3. DATE ---
         final dateMatch = dateRegex.firstMatch(currentChunk);
         if (dateMatch == null) {
            print("Skipping Tx $txId: Date not found.");
            continue;
         }
         final dateStr = dateMatch.group(1)!;

         // --- 4. NAME (from Previous) ---
         // Look at the last 500 chars of previous chunk
         final prevTail = previousChunk.length > 500 
            ? previousChunk.substring(previousChunk.length - 500) 
            : previousChunk;
         
         final nameMatches = namePattern.allMatches(prevTail);
         
         String typeStr = "Paid to"; 
         String nameRaw = "Unknown";
         
         if (nameMatches.isNotEmpty) {
            // Check matches to find the one closest to the end (The "Active" one)
            // But usually the last one is correct because "Paid to" precedes the ID.
            final lastMatch = nameMatches.last;
            typeStr = lastMatch.group(1)!;
            nameRaw = lastMatch.group(2)!;
         } 

         // Clean Name
         final name = nameRaw.replaceAll('\n', ' ').trim();
         final bool isCredit = typeStr.toLowerCase().contains('received');

         // Parse Date
         String cleanDateStr = dateStr.replaceAll(RegExp(r'[\s\-\/]+'), ' ').trim(); 
         
         if (!cleanDateStr.contains(',')) {
            // Fix "8 Jan 2026" -> "8 Jan, 2026"
            // Ensure month (3 letters) is separated from year (4 digits) by comma
             cleanDateStr = cleanDateStr.replaceAllMapped(
               RegExp(r'([A-Za-z]{3})\s+(\d{4})'), 
               (m) => '${m.group(1)}, ${m.group(2)}'
             );
         }

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

         // Check for Duplicates? No, we trust the ID uniqueness in DatabaseService.
         // But logic here just creates the model.
         
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
