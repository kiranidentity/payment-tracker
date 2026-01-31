import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class UnifiedGradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottomContent;
  final bool showBrand;
  final bool canGoBack;

  const UnifiedGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottomContent,
    this.showBrand = true,
    this.canGoBack = false,
  });

  @override
  Widget build(BuildContext context) {
    // Adaptive top padding
    final topPadding = MediaQuery.of(context).padding.top + 16;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BRAND ROW (Always Top)
          if (showBrand) ...[
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pie_chart_outline, color: Colors.white.withOpacity(0.9), size: 14),
                      const SizedBox(width: 8), // Increased spacing for better breathability
                      const Text(
                        'PAYMENT TRACKER',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 11, // Slightly larger
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.0
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12), // Reduced height slightly to connect with title
          ],

          // TITLE ROW
          Row(
            children: [
              if (canGoBack)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (canGoBack) const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 22, // Larger, prominent title
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),

          // OPTIONAL BOTTOM CONTENT (e.g. Month Selector, Tabs placeholder, etc)
          if (bottomContent != null) ...[
            const SizedBox(height: 16),
            bottomContent!,
          ]
        ],
      ),
    );
  }
}
