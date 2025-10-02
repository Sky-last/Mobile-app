import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_app_5sia1/models/note_model.dart';
import 'package:notes_app_5sia1/constants/app_colors.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get gradient colors for category
    List<Color> gradientColors = AppColors.categoryGradients[0];
    if (note.category != null && note.categoryColor != null) {
      try {
        final color = AppColors.fromHex(note.categoryColor!);
        gradientColors = [color.withOpacity(0.6), color];
      } catch (e) {
        gradientColors = AppColors.getGradientForCategory(note.category);
      }
    }

    return Hero(
      tag: 'note_${note.noteId}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: note.category != null
                  ? LinearGradient(
                      colors: [
                        gradientColors[0].withOpacity(0.1),
                        gradientColors[1].withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: note.category == null
                  ? (isDark ? AppColors.cardDark : AppColors.cardLight)
                  : null,
              boxShadow: [
                BoxShadow(
                  color:
                      (note.category != null ? gradientColors[1] : Colors.grey)
                          .withOpacity(0.15),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main Content
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Pin Icon
                          InkWell(
                            onTap: onTogglePin,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: note.isPinned == 1
                                    ? Colors.teal.withOpacity(0.2)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                note.isPinned == 1
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                size: 18,
                                color: note.isPinned == 1
                                    ? Colors.teal
                                    : Colors.grey,
                              ),
                            ),
                          ),

                          Spacer(),

                          // Reminder Indicator
                          if (note.reminderTime != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_active,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d').format(
                                      DateTime.parse(note.reminderTime!),
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(width: 8),

                          // Delete Button
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Title
                      Text(
                        note.noteTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 8),

                      // Content Preview
                      Text(
                        note.noteContent,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 12),

                      // Footer
                      Row(
                        children: [
                          // Category Chip
                          if (note.category != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradientColors,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradientColors[1].withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                note.category!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          Spacer(),

                          // Date
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'MMM d, y',
                                ).format(DateTime.parse(note.createdAt)),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Category Color Indicator (Left Border)
                if (note.category != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
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
