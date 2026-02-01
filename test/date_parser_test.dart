import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  test('Reproduce Date Parsing Logic', () {
    // Raw text snippet from debug dump
    // Note the newlines
    final rawSnippet = '''
01
Oct,
2025
08:33
AM
Paid
to
''';

    // The Regex I used
    final dateRegex = RegExp(r'(\d{1,2})[\s\-\/\n]+([A-Za-z]{3})[\s\-\/,\n]+(\d{4})[\s\n]+(\d{2}:\d{2}[\s\n]+[AP]M)');

    final match = dateRegex.firstMatch(rawSnippet);
    
    if (match == null) {
      print("REGEX FAILED TO MATCH");
      return;
    }
    
    print("Match found!");
    print("Group 1 (Day): '${match.group(1)}'");
    print("Group 2 (Month): '${match.group(2)}'");
    print("Group 3 (Year): '${match.group(3)}'");
    print("Group 4 (Time): '${match.group(4)}'");

    final day = match.group(1)!;
    final month = match.group(2)!;
    final year = match.group(3)!;
    // Current logic: replaceAll('\n', ' ')
    final time = match.group(4)!.replaceAll('\n', ' '); 
    
    final cleanDateStr = "$day $month, $year $time";
    print("Clean String: '$cleanDateStr'");

    final dateFormat = DateFormat("d MMM, yyyy hh:mm a");
    try {
      final date = dateFormat.parse(cleanDateStr);
      print("Parsed Successfully: $date");
    } catch (e) {
      print("PARSE ERROR: $e");
    }
  });
}
