import 'package:buddy/providers/calendar_event_provider.dart';
import 'package:buddy/screens/navigation_screen.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:buddy/widgets/my_table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventsHomePreview extends ConsumerWidget {
  const EventsHomePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => NavigationScreen.switchToTab(3),
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.adaptSize(10.w, ),
          vertical: context.adaptSize(9.h,),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _previewEvents(ref, context),
        ),
      ),
    );
  }
}

List<Widget> _previewEvents(WidgetRef ref, BuildContext context) {
  final upComing = ref.watch(upcomingEventsProvider).take(2).toList();
  DateTime focusedDay = DateTime.now();

  if (upComing.isEmpty) {
    return [
      Text(
        'No upcoming events',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: context.adaptSize(18.sp, tab: 14.sp),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: MyTableCalendar(
          focusedDay: focusedDay,
          calendarHeight: context.adaptSize(110.h,tab: 90.h),
          useWeekFormat: true,
          rowHeight: context.adaptSize(28.h, tab: 40.h),
          onPageChanged: null,
          onDaySelected: null,
          selectedDay: null,
        ),
      ),
    ];
  }

  return [
    MyTableCalendar(
      focusedDay: focusedDay,
      calendarHeight: context.adaptSize(302.h, tab: 290.h),
      useWeekFormat: false,
      rowHeight: context.adaptSize(38.h, tab: 38.h),
      onPageChanged: null,
      onDaySelected: null,
      selectedDay: null,
    ),
  ];
}
