import 'package:buddy/models/task_model.dart';
import 'package:buddy/providers/tasks_provider.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class TaskTile extends ConsumerWidget {
  final Task task;
  final void Function(bool?) onChanged;

  const TaskTile({super.key, required this.task, required this.onChanged});

  String formatTasksDateTime(DateTime startTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    final timeString = DateFormat.jm().format(startTime); // eg 10:00 AM

    if (eventDate == today) {
      return 'Today , $timeString';
    } else if (eventDate == tomorrow) {
      return 'Tomorrow, $timeString';
    } else {
      final dateString = DateFormat('MMM d').format(startTime);
      return '$dateString , $timeString';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            borderRadius: BorderRadius.circular(8.r),
            onPressed: (context) =>
                ref.read(tasksProvider.notifier).deleteTask(task.id),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      key: ValueKey(task.id),

      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(8.r),
          border: Border(
            left: BorderSide(
              width: 7.w,
              color: _getPriorityColor(task.priority).withValues(alpha: 0.8),
            ),
          ),
        ),
        child: ListTile(
          trailing: task.hasReminder
              ? Icon(
                  Icons.notifications_active_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: context.adaptSize(25.sp,tab: 18.sp),
                )
              : null,
          // checkbox
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: onChanged,
            shape: CircleBorder(),
          ),
          // task title
          title: Text(
            task.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: context.adaptSize(15.sp, tab: 12.sp),
              fontWeight: FontWeight.w500,
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationThickness: task.isCompleted ? 2 : null,
            ),
          ),
          // reminder date
          subtitle: task.hasReminder && task.reminderTime != null
              ? Text(
                  formatTasksDateTime(task.reminderTime!),
                  style: TextStyle(
                    fontSize: context.adaptSize(13.sp,tab: 10.sp),
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

Color _getPriorityColor(Priority priority) {
  switch (priority) {
    case Priority.low:
      return Colors.green;
    case Priority.medium:
      return Colors.amber;
    case Priority.high:
      return Colors.red;
  }
}
