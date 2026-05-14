import 'package:flutter/material.dart';
import 'package:peci_project/core/theme/app_theme.dart';

class RuleItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final Widget? extra;

  const RuleItem({super.key, 
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 3),
              Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
              if (extra != null) ...[const SizedBox(height: 6), extra!],
            ],
          ),
        ),
      ],
    );
  }
}