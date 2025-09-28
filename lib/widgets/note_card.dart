import 'package:buddy/providers/notes_provider.dart';
import 'package:buddy/transition_class/dart/app_navigator.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../models/note_model.dart';
import '../screens/edit_note_screen.dart';

class NoteTile extends ConsumerWidget {
  final Note note;

  const NoteTile({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayDate = note.updatedAt.isAfter(note.createdAt)
        ? note.updatedAt
        : note.createdAt;
    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            borderRadius: BorderRadius.circular(12.r),
            onPressed: (context) =>
                ref.read(notesProvider.notifier).deleteNote(note.id, ref),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      key: ValueKey(note.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          AppNavigator.push(
            context,
            EditNotesScreen(existingNote: note),
            type: TransitionType.cupertino,
          );
        },
        child: Container(
          padding: EdgeInsets.all(context.adaptPadding(10.r, tab: 8.r)),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ListTile(
            title: Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              note.title,
              style: TextStyle(
                fontSize: context.adaptSize(16.sp, tab: 12.sp),
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  formatDateTime(displayDate),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                    fontSize: context.adaptSize(13.sp, tab: 10.sp),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    maxLines: 1,
                    note.subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: context.adaptSize(13.sp, tab: 10.sp),

                      overflow: TextOverflow.ellipsis,
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

// helper to format date time.
String formatDateTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date).inDays;

  if (difference == 0) {
    // Today -> show time(HH:mm)
    return DateFormat('HH:mm').format(date);
  } else if (difference > 0 && difference < 7) {
    // within 7 days -> weekday
    return DateFormat('EEE').format(date);
  } else if (difference >= 7 && difference < 30) {
    // Within 30 days -> dd/MM/yy
    return DateFormat('dd/MM/yyy').format(date);
  } else {
    // Older than 30 days -> month name
    return DateFormat('MMMM').format(date);
  }
}
