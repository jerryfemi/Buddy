import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/calendar_event_provider.dart';

extension DateTimeWeekExtension on DateTime {
  int get weekOfYear {
    final dayOfYear = int.parse(DateFormat('D').format(this));
    return ((dayOfYear - weekday + 10) / 7).floor();
  }
}

class MyTableCalendar extends ConsumerWidget {
  final double calendarHeight;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>?
  onDaySelected; // Callback to calendarHeaderDelegate
  final ValueChanged<DateTime>?
  onPageChanged; // Callback to calendarHeaderDelegate
  final bool useWeekFormat;
  final double rowHeight;

  const MyTableCalendar({
    super.key,
    required this.focusedDay,
    required this.calendarHeight,
    required this.useWeekFormat,
    required this.rowHeight,
    this.onPageChanged,
    this.onDaySelected,
    this.selectedDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<dynamic> eventLoader(DateTime day) {
      return ref.watch(eventsForDateProvider(day));
    }

    return SizedBox(
      height: calendarHeight,
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: TableCalendar(
            focusedDay: focusedDay,
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            calendarFormat: useWeekFormat
                ? CalendarFormat.week
                : CalendarFormat.month,
            rowHeight: rowHeight,
            daysOfWeekHeight: 20.h,
            onPageChanged: onPageChanged,

            // Calls _CalendarSliverState's onPageChanged handler
            selectedDayPredicate: (day) =>
                selectedDay != null && isSameDay(selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              // Notify _CalendarSliverState about the selection
              if (onDaySelected != null) {
                onDaySelected!(selectedDay);
              }
              // Also notify _CalendarSliverState about the focused day change
              if (onPageChanged != null) {
                onPageChanged!(focusedDay);
              }
            },
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            calendarStyle: CalendarStyle(
              // selected date background
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),

              // today’s date background
            ),
            //  highlight days with events
            eventLoader: eventLoader,
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = [
                  'Sun',
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thur',
                  'Fri',
                  'Sat',
                  'Sun',
                ][day.weekday % 7];
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final isSelected =
                    selectedDay != null && isSameDay(selectedDay, day);

                //  uniform opacity: 1.0 in week format, otherwise 0.7 for all
                final baseOpacity = useWeekFormat ? 0.9 : 0.75;
                final opacity = isSelected ? 1.0 : baseOpacity;

                return Opacity(
                  opacity: opacity,
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ),
                );
              },

              // selected builder
              selectedBuilder: (context, day, focusedDay) {
                return Center(
                  child: FittedBox(
                    child: Container(
                      padding: EdgeInsetsGeometry.all(6.r),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ),
                );
              },

              // outside builder
              outsideBuilder: (context, day, focusedDay) {
                return Center(
                  child: FittedBox(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                );
              },

              // today builder
              todayBuilder: (context, day, focusedDay) {
                return Center(
                  child: FittedBox(
                    child: Container(
                      padding: EdgeInsetsGeometry.all(6.r),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ),
                );
              },

              // header
              headerTitleBuilder: (context, date) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.yMMMM().format(date),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      IconButton(
                        icon: Icon(
                          Icons.calendar_month,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ],
                  ),
                );
              },
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }
}
