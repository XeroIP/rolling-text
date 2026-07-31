import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final AppColors colors;
  final VoidCallback onPressed;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.buttonBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: colors.buttonIcon, size: 24),
          ),
        ),
      ),
    );
  }
}
