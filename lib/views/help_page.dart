import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';


class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Process Flow
            _buildSectionTitle('How it Works'),
            const SizedBox(height: 16),
            _buildProcessFlow(),
            const SizedBox(height: 32),

            // 2. Value Proposition
            _buildSectionTitle('Why Payment Tracker?'),
            const SizedBox(height: 16),
            _buildValueProp(
              Icons.privacy_tip_outlined, 
              '100% Private & Offline', 
              'Your financial data never leaves this device. We track payments locally without sending data to any server.'
            ),
            _buildValueProp(
              Icons.auto_fix_high, 
              'Smart Automation', 
              'Map a name once, and we remember it forever. Future statements are processed instantly.'
            ),

            const SizedBox(height: 32),

            // 3. Step-by-Step Guide
            _buildSectionTitle('Quick Guide'),
            const SizedBox(height: 16),
            _buildGuideStep(1, 'Import Statement', 'Tap the "Import Statement" button and select your PDF bank statement.'),
            _buildGuideStep(2, 'Map Clients', 'For new names, tap "Map" and assign them to a Client Profile (e.g. "Rahul").'),
            _buildGuideStep(3, 'Review & Track', 'The dashboard updates automatically. If someone overpaid, use the "Review" button to mark it as Bonus or Advance.'),

            const SizedBox(height: 32),

            // 4. FAQs
            _buildSectionTitle('Frequently Asked Questions'),
            const SizedBox(height: 16),
            _buildFaqItem('Does it track my spending?', 'No. We strictly track "Money In" (Credits) to help you manage fees. Debits are ignored.'),
            _buildFaqItem('What if a client pays from a different name?', 'No problem! You can map multiple "Sender Names" (Aliases) to the same Client Profile.'),
            _buildFaqItem('Can I delete a client?', 'Yes. Long press or swipe on a client in the list to delete them.'),
             _buildFaqItem('I upgraded my phone. How do I transfer data?', 'Currently, data is strictly on-device. We are working on a Backup feature.'),
             
             const SizedBox(height: 32),

             // 5. Glossary
             _buildSectionTitle('Glossary'),
             const SizedBox(height: 16),
             _buildGlossaryItem('Entity / Client', 'A person or student who pays you (e.g. "Rahul").'),
             _buildGlossaryItem('Sender Name', 'The name that appears on your bank statement.'),
             _buildGlossaryItem('Mapping', 'Linking a "Sender Name" to a "Client" so future payments are auto-recognized.'),
             _buildGlossaryItem('Unmapped', 'A payment from a sender we do not recognize yet.'),
             _buildGlossaryItem('Alias', 'An alternate name for a client (e.g. if Rahul pays from "Rahul Father" account).'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
    );
  }

  Widget _buildProcessFlow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFlowStep(Icons.upload_file, 'Upload'),
          const Icon(Icons.arrow_forward, color: Colors.grey),
          _buildFlowStep(Icons.link, 'Map'),
          const Icon(Icons.arrow_forward, color: Colors.grey),
          _buildFlowStep(Icons.pie_chart, 'Track'),
        ],
      ),
    );
  }

  Widget _buildFlowStep(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildValueProp(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppTheme.textSub, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGuideStep(int step, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppTheme.textSub)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer, style: const TextStyle(color: AppTheme.textSub)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlossaryItem(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: AppTheme.textSub, height: 1.4),
                children: [
                  TextSpan(text: '$term: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                  TextSpan(text: definition),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
