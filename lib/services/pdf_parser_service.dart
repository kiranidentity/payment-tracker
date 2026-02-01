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
    
    // STRATEGY: Split by "UPI Transaction ID".
    // This anchors every transaction.
    // Chunk 0: Header + Name of Tx 1
    // Chunk 1: ID of Tx 1 + Body of Tx 1 + Name of Tx 2
    // Chunk N: ID of Tx N + Body of Tx N + Footer
    
    // We use a case-insensitive split
    final delimiter = RegExp(r'UPI\s+Transaction\s+ID:\s*', caseSensitive: false);
    final chunks = text.split(delimiter);

    if (chunks.length <= 1) {
      print("DEBUG: No UPI Transaction IDs found.");
      return [];
    }

    // We start from 1 because chunks[0] is just the header/preamble for the first Tx.
    // We define Tx[i] using chunks[i] (which has ID, Amount, Date) and chunks[i-1] (for Name).
    
    // Helper Regexes for extracting within a chunk
    // ID is at the start of the chunk (implied, but split consumes the label, so it's just digits)
    final idRegex = RegExp(r'^(\d+)');
    
    // Amount: Look for ₹ followed by digits/commas
    final amountRegex = RegExp(r'₹\s*([\d,]+)');
    
    // Date: Flexible match
    // Matches "8 Jan" or "08 Jan", optional comma, year, time
    final dateRegex = RegExp(r'(\d{1,2}\s+[A-Za-z]{3}.*?\d{4}\s+\d{2}:\d{2}\s+[AP]M)');

    // Name: Found in the PREVIOUS chunk, near the end.
    // Usually: "Paid to/Received from [NAME]"
    final nameRegex = RegExp(r'(Paid\s+to|Received\s+from)\s+([A-Za-z0-9\s\.\-\&]+)$', caseSensitive: false);

    for (int i = 1; i < chunks.length; i++) {
       try {
         final currentChunk = chunks[i].trim();
         final previousChunk = chunks[i-1].trim();

         // 1. EXTRACT ID
         final idMatch = idRegex.firstMatch(currentChunk);
         if (idMatch == null) continue; // Should not happen if split worked
         final txId = idMatch.group(1)!;

         // 2. EXTRACT AMOUNT
         final amountMatch = amountRegex.firstMatch(currentChunk);
         if (amountMatch == null) {
            print("Skipping Tx $txId: Amount not found");
            continue;
         }
         final amountStr = amountMatch.group(1)!.replaceAll(',', '');

         // 3. EXTRACT DATE
         final dateMatch = dateRegex.firstMatch(currentChunk);
         if (dateMatch == null) {
            print("Skipping Tx $txId: Date not found");
            continue;
         }
         final dateStr = dateMatch.group(1)!;

         // 4. EXTRACT NAME (From Previous Chunk)
         // We look at the very end of the previous chunk
         // But "Paid to" might be far back if there's junk.
         // Let's take the last 100 chars of prev chunk to be safe
         final prevTail = previousChunk.length > 200 
            ? previousChunk.substring(previousChunk.length - 200) 
            : previousChunk;
         
         final nameMatch = nameRegex.firstMatch(prevTail);
         // If standard "Paid to" regex fails, try a fallback?
         // Maybe just grab the text after "Received from" or "Paid to"
         // Actually currentRegex looks for 'Expected Pattern' at the END ($).
         // The split might have left "Paid to Rahul " (trailing space). trim() handles that.
         
         String typeStr = "Paid to"; 
         String nameRaw = "Unknown";
         
         if (nameMatch != null) {
            typeStr = nameMatch.group(1)!;
            nameRaw = nameMatch.group(2)!;
         } else {
            // Fallback: Try to find any "Paid to" in the tail
            final looseNameMatch = RegExp(r'(Paid\s+to|Received\s+from)\s+(.*?)$').firstMatch(prevTail);
            if (looseNameMatch != null) {
               typeStr = looseNameMatch.group(1)!;
               nameRaw = looseNameMatch.group(2)!;
            }
         }

         // Clean Name
         final name = nameRaw.replaceAll('\n', ' ').trim();
         final bool isCredit = typeStr.toLowerCase().contains('received');

         // Parse Date
         // E.g. "8 Jan, 2026 08:41 PM"
         // Cleaning: Remove extra spaces, fix potential weird commas
         String cleanDateStr = dateStr.replaceAll(RegExp(r'\s+'), ' ').trim();
         // Insert comma if missing between Month and Year? "8 Jan 2026" -> "8 Jan, 2026"
         // DateFormat("d MMM, yyyy") expects matching format.
         // Let's try to normalize: "8 Jan 2026" -> Add comma?
         if (!cleanDateStr.contains(',')) {
            // Try to insert comma after month (3 letters)
            // Regex: (\d+ [A-Za-z]{3}) (\d{4})
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
            date = DateTime.now(); // Fallback
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
