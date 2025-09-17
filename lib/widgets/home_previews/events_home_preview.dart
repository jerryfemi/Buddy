import 'package:buddy/providers/calendar_event_provider.dart';
import 'package:buddy/screens/navigation_screen.dart';
import 'package:buddy/widgets/my_table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventsHomePreview extends ConsumerWidget {
  const EventsHomePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => NavigationScreen.switchToTab(context, 3),
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _previewEvents(ref),
        ),
      ),
    );
  }
}

List<Widget> _previewEvents(WidgetRef ref) {
  final upComing = ref.watch(upcomingEventsProvider).take(2).toList();
  DateTime focusedDay = DateTime.now();

  if (upComing.isEmpty) {
    return [
      Padding(
        padding: EdgeInsets.only(top: 16.r),
        child: Text(
          'No upcoming events',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
      ),
      MyTableCalendar(
        focusedDay: focusedDay,
        calendarHeight: 130.h,
        useWeekFormat: true,
        rowHeight: 30.h,
        onPageChanged: null,
        onDaySelected: null,
        selectedDay: null,
      ),
    ];
  }

  return [
    MyTableCalendar(
      focusedDay: focusedDay,
      calendarHeight: 338.h,
      useWeekFormat: false,
      rowHeight: 43.h,
      onPageChanged: null,
      onDaySelected: null,
      selectedDay: null,
    ),
  ];
}
