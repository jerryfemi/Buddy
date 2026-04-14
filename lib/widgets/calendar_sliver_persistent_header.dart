import 'package:buddy/widgets/my_table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarSliver extends ConsumerStatefulWidget {
  final DateTime? selectedDay;
  final ValueChanged<DateTime?> onDaySelected;
  final DateTime focusedDay; // Keep as final (or late final)
  final ValueChanged<DateTime> onFocusedDayChanged; // New callback
  final double maxHeight;
  final double minHeight;

  const CalendarSliver({
    super.key,
    required this.selectedDay,
    required this.maxHeight,
    required this.minHeight,
    required this.onDaySelected,
    required this.focusedDay,
    required this.onFocusedDayChanged, // Add to constructor
  });

  @override
  ConsumerState<CalendarSliver> createState() => _CalendarSliverState();
}

class _CalendarSliverState extends ConsumerState<CalendarSliver> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CalendarHeaderDelegate(
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight,
        selectedDay: widget.selectedDay,
        focusedDay: widget.focusedDay,
        calendarFormat: _calendarFormat,
        onDaySelected: (day) {

          setState(() {
            if (widget.selectedDay != null &&
                isSameDay(widget.selectedDay, day)) {
              widget.onDaySelected(null);
            } else {
              widget.onDaySelected(day);

            }
          });
        },
        onPageChanged: (newFocusedDay) {

          widget.onFocusedDayChanged(
            newFocusedDay,
          ); // Notify parent (RemindersScreen)
        },
      ),
    );
  }
}

class _CalendarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final DateTime? selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final ValueChanged<DateTime>
  onDaySelected; // Callback to _CalendarSliverState
  final ValueChanged<DateTime>
  onPageChanged; // Callback to _CalendarSliverState

  _CalendarHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.selectedDay,
    required this.focusedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double availableHeight = maxHeight - shrinkOffset;
    final double calendarHeight = availableHeight.clamp(minHeight, maxHeight);
    final double progress = (shrinkOffset / (maxHeight - minHeight)).clamp(
      0.0,
      1.0,
    );
    final bool useWeekFormat = progress > 0.83;
    final double kChrome = 110.h;
    final double monthRowHeight = ((calendarHeight - kChrome) / 6).clamp(
      20.0,
      150.0,
    );
    final double weekRowHeight = (minHeight - kChrome).clamp(20.0, 70.0);
    final double rowHeight = useWeekFormat ? weekRowHeight : monthRowHeight;

    return Material(
      child: MyTableCalendar(
        focusedDay: focusedDay,
        calendarHeight: calendarHeight,
        useWeekFormat: useWeekFormat,
        rowHeight: rowHeight,
        onPageChanged: onPageChanged,
        onDaySelected: onDaySelected,
        selectedDay: selectedDay,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CalendarHeaderDelegate oldDelegate) {
    return oldDelegate.selectedDay != selectedDay ||
        oldDelegate.focusedDay != focusedDay ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.onDaySelected != onDaySelected ||
        oldDelegate.onPageChanged != onPageChanged;
  }
}
