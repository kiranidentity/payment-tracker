import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final String title;

  const GlobalAppBar({
    super.key,
    this.leading,
    this.actions,
    this.title = 'PAYMENT TRACKER',
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primaryDark,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 48,
      leading: leading ?? Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.pie_chart_outline, color: Colors.white.withOpacity(0.9), size: 18),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
