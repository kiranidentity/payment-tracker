import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthNavigationHeader extends StatelessWidget {
  final DateTime currentDate;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool canGoPrevious;
  final bool canGoNext;

  const MonthNavigationHeader({
    super.key,
    required this.currentDate,
    this.onPrevious,
    this.onNext,
    this.canGoPrevious = false,
    this.canGoNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spread to edges or center? HomePage was center.
      // Actually, standardizing on Centered for Title, but if we want it to look like a control bar, maybe spread is better?
      // User liked HomePage better implicitly. Let's stick to Centered Row for now, 
      // but let's make it look premium.
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNavButton(
          icon: Icons.chevron_left,
          onTap: canGoPrevious ? onPrevious : null,
          tooltip: "Previous Month",
        ),
        const SizedBox(width: 20),
        
        // Month Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM yyyy').format(currentDate),
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontSize: 16,
                  letterSpacing: 0.5
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 20),
        _buildNavButton(
          icon: Icons.chevron_right,
          onTap: canGoNext ? onNext : null,
          tooltip: "Next Month",
        ),
      ],
    );
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onTap, required String tooltip}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          color: onTap != null ? Colors.white : Colors.white24, 
          size: 24
        ),
      ),
    );
  }
}
