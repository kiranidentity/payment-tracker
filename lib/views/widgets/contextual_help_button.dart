import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ContextualHelpButton extends StatelessWidget {
  final String title;
  final String content;
  final Color? iconColor;

  const ContextualHelpButton({
    super.key,
    required this.title,
    required this.content,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.info_outline, color: iconColor ?? Colors.grey.shade400, size: 18),
      tooltip: 'Info',
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.accent),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
              ],
            ),
            content: Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      },
    );
  }
}
