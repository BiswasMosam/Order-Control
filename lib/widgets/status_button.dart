import 'package:flutter/material.dart';

import '../theme.dart';

/// Wide, flat toggle used for Ready / Paid / Done. Sized for a thumb tap
/// without looking, which is the whole point of the board.
class StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const StatusButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? color : AppColors.line,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: active ? Colors.black : AppColors.textDim,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: active ? Colors.black : AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
