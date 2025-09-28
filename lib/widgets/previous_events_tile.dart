import 'package:buddy/models/previous_events_model.dart';
import 'package:buddy/providers/previous_events_provider.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class PreviousEventsTile extends ConsumerStatefulWidget {
  final PreviousEvents event;

  const PreviousEventsTile({super.key, required this.event});

  @override
  ConsumerState<PreviousEventsTile> createState() => _EventsListTileState();
}

class _EventsListTileState extends ConsumerState<PreviousEventsTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        extentRatio: 0.3,
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              ref
                  .read(previousEventsProvider.notifier)
                  .permanentlyDeleteEvents(widget.event.id);
            },
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            icon: Icons.delete,
            label: 'delete',
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2.h,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          child: ListTile(
            title: Text(
              widget.event.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: context.adaptSize(16.sp, tab: 12.sp),
              ),
            ),

            subtitle: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCrossFade(
                  firstChild: SizedBox.shrink(),
                  secondChild: widget.event.description != null
                      ? Text(
                          widget.event.description!,
                          style: TextStyle(
                            fontSize: context.adaptSize(13.sp, tab: 10.sp),
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : SizedBox.shrink(),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                Text(
                  formatEventDateTime(widget.event.startDateTime),
                  style: TextStyle(
                    fontSize: context.adaptSize(13.sp, tab: 10.sp),
                    color: Theme.of(context).colorScheme.tertiary,
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

String formatEventDateTime(DateTime startTime) {
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
