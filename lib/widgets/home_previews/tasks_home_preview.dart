import 'package:buddy/models/task_model.dart';
import 'package:buddy/providers/tasks_provider.dart';
import 'package:buddy/screens/navigation_screen.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class TasksHomePreview extends ConsumerWidget {
  const TasksHomePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final percent = ref.read(tasksProvider.notifier).completionFraction;
    return InkWell(
      borderRadius: BorderRadius.circular(15.r),
      enableFeedback: true,
      onTap: () => NavigationScreen.switchToTab( 2),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.adaptSize(9.h, ),
          horizontal: context.adaptSize(10.w,),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header
                  Text(
                    'Tasks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.adaptSize(18.sp,tab: 14.sp),
                    ),
                  ),
                  // list of tasks
                  ..._previewTasks(ref, tasks, context),
                ],
              ),
            ),
             FittedBox(
                fit: BoxFit.scaleDown,
                child: CircularPercentIndicator(
                  radius:  context.adaptSize(38.r,tab: 34.r) ,
                  animationDuration: 850,
                  animation: true,
                  animateFromLastPercent: true,
                  circularStrokeCap: CircularStrokeCap.round,
                  lineWidth:  5.w,
                  curve: Curves.easeInOut,
                  percent: percent,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  progressColor: Theme.of(context).colorScheme.primary,
                  center: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${(percent * 100).round()}%',
                      style: TextStyle(
                        fontSize: context.adaptSize(14.sp,tab: 12.sp),
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// preview card
List<Widget> _previewTasks(
  WidgetRef ref,
  List<Task> tasks,
  BuildContext context,
) {
  // show up to 3 tasks as previews
  final preview = tasks.take(3).toList();

  if (preview.isEmpty) {
    return [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Text(
          'No Tasks yet.',
          style: TextStyle(fontSize: context.isTab? 10.sp:null,)
        ),
      ),
    ];
  }

  return preview.map((task) {
    return context.isMobile
        ? Row(
            children: [
              // quick checkBox
              Checkbox(
                shape: CircleBorder(),
                value: task.isCompleted,
                onChanged: (value) =>
                    ref.read(tasksProvider.notifier).toggleTask(task.id),
              ),
              Expanded(
                child: Text(
                  task.title,maxLines: 1,overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.adaptSize(12.sp,),

                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? Theme.of(context).colorScheme.tertiary
                        : null,
                  ),
                ),
              ),
            ],
          )
        : ListTile(
            leading: Checkbox(
              shape: CircleBorder(),
              value: task.isCompleted,
              onChanged: (value) =>
                  ref.read(tasksProvider.notifier).toggleTask(task.id),
            ),
            title: Text(
              task.title,maxLines: 1,overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.adaptSize(12.sp),

                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: task.isCompleted
                    ? Theme.of(context).colorScheme.tertiary
                    : null,
              ),
            ),
          );
  }).toList();
}
