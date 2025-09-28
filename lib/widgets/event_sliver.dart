import 'package:buddy/models/calendar_event_model.dart';
import 'package:buddy/providers/calendar_event_provider.dart';
import 'package:buddy/providers/previous_events_provider.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:buddy/widgets/add_events_sheet.dart';
import 'package:buddy/widgets/previous_events_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../models/previous_events_model.dart';
import 'events_list_tile.dart';

class EventsSliver extends ConsumerStatefulWidget {
  final DateTime? selectedDay;

  const EventsSliver({super.key, required this.selectedDay});

  @override
  ConsumerState<EventsSliver> createState() => _EventsSliverState();
}

class _EventsSliverState extends ConsumerState<EventsSliver> {
  bool showUpcoming = true; // toggle state: true = upcoming, false = previous

  @override
  Widget build(BuildContext context) {
    final isDaySelected = widget.selectedDay != null;

    // Pick the right provider depending on toggle
    final events = showUpcoming
        ? (isDaySelected
              ? ref.watch(eventsForDateProvider(widget.selectedDay!))
              : ref.watch(upcomingEventsProvider))
        : ref.watch(previousEventsProvider);

    if (events.isEmpty) {
      // Empty state sliver (nothing to show)
      return SliverToBoxAdapter(child: _buildEmptyState(isDaySelected));
    }

    // When events exist, return a sliver list with a header + event tiles
    return MultiSliver(
      children: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: 16.w, top: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildToggle(), // toggle buttons
                SizedBox(height: 10.h),
                if (!showUpcoming)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => showClearAllDialog(context, ref),
                        child: Text('clear all',style: TextStyle(fontSize: 10.sp),),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // List of events
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final event = events[index];

            // Render the right tile based on type
            if (showUpcoming && event is CalendarEvent) {
              return EventsListTile(event: event);
            } else if (!showUpcoming && event is PreviousEvents) {
              return PreviousEventsTile(event: event);
            } else {
              return const SizedBox.shrink();
            }
          }, childCount: events.length),
        ),
      ],
    );
  }

  // Empty state
  // ---------------------------------------------------
  Widget _buildEmptyState(bool isDaySelected) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggle(),

          SizedBox(height: 20.h),
          Center(
            child: Column(
              children: [
                Text(
                  showUpcoming
                      ? (isDaySelected
                            ? 'No events for ${_formatDate(widget.selectedDay!)}'
                            : 'No upcoming events')
                      : 'No previous events',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,fontSize:context.isTab? 10.sp:null
                  ),
                ),
                // Only allow adding events in "upcoming" mode
                if (showUpcoming)
                  TextButton(
                    onPressed: openAddEventsDialog,
                    child:  Text('Add Events',style: TextStyle(fontSize:context.isTab? 10.sp: null),),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Toggle buttons (switch between Events / Previous)
  // ---------------------------------------------------
  Widget _buildToggle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            // Upcoming events button
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(6.r),
                onTap: () => setState(() {
                  showUpcoming = true;
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal:  context.adaptSize(10.w,tab: 8.w),
                    vertical:  context.adaptSize(8.h,tab: 6.h),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    color: showUpcoming
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.6)
                        : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Events',
                      style: TextStyle(
                        fontSize: context.adaptSize(14.sp,tab: 12.sp),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Previous events button
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(6.r),
                onTap: () => setState(() {
                  showUpcoming = false;
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal:  context.adaptSize(10.w,tab: 8.w),
                    vertical:  context.adaptSize(8.h,tab: 6.h),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    color: !showUpcoming
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.6)
                        : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Previous events',
                      style: TextStyle(
                        fontSize: context.adaptSize(14.sp,tab: 12.sp),
                        fontWeight: FontWeight.w400,
                      ),
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

  // Bottom sheet to add event
  // ---------------------------------------------------
  void openAddEventsDialog() {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: context.adaptSize(0.6, tab: 0.5),
        minChildSize: 0.37,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return AddEventSheet(scrollController: scrollController);
        },
      ),
    );
  }

  //Helper: Format date nicely for header
  // ---------------------------------------------------
  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

Future<void> showClearAllDialog(BuildContext context, WidgetRef ref) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear all'),
      content: const Text(
        'Are you sure you want to clear all Previous Events?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cancel
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.of(context).pop(); // Close dialog
            await ref
                .read(previousEventsProvider.notifier)
                .clearPreviousEvents();
          },
          child: const Text('Clear all'),
        ),
      ],
    ),
  );
}
