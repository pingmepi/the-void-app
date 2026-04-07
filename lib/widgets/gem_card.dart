import 'package:flutter/material.dart';

import '../main.dart';
import '../models/gem_note.dart';

class GemCard extends StatelessWidget {
  const GemCard({
    super.key,
    required this.gem,
    required this.onTap,
    required this.onDelete,
  });

  final GemNote gem;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatDate(DateTime dt) =>
      '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  static String formatDuration(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  String get _displayTitle {
    if (gem.title != null && gem.title!.isNotEmpty) return gem.title!;
    final t = gem.transcript;
    return t.length > 60 ? t.substring(0, 60) : t;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VoidColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: VoidColors.textGhost.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: gem.title != null && gem.title!.isNotEmpty
                          ? VoidColors.textPrimary
                          : VoidColors.textSecondary,
                      fontSize: 15,
                      fontFamily: 'serif',
                      height: 1.4,
                    ),
                  ),
                ),
                if (gem.durationSeconds != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    key: const Key('gem_duration'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: VoidColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatDuration(gem.durationSeconds!),
                      style: TextStyle(
                        color: VoidColors.accent.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(gem.savedAt),
                  style: TextStyle(
                    color: VoidColors.textFaded,
                    fontSize: 12,
                    fontFamily: 'serif',
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(
                      Icons.delete_outline,
                      color: VoidColors.textFaded,
                    ),
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
