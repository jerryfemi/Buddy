import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MiniMonth extends StatelessWidget {
  final int year;
  final int month;

  const MiniMonth({super.key, required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;

    // Get today's date
    final DateTime now = DateTime.now();
    final int currentYear = now.year;
    final int currentMonth = now.month;
    final int currentDay = now.day;

    final startWeekday = firstDay.weekday % 7;
    final days = List.generate(
      startWeekday + daysInMonth,
      (i) => i < startWeekday ? null : i - startWeekday + 1,
    );
    return Column(
      children: [
        // weekday headers
        _weekDayHeaders(Theme.of(context).colorScheme.tertiary,context),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              if (day == null) {
                return const SizedBox.shrink();
              }
              bool isToday = false;
              if (year == currentYear &&
                  month == currentMonth &&
                  day == currentDay) {
                isToday = true;
              }
              return RepaintBoundary(
                child: Container(
                  decoration: isToday
                      ? BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        )
                      : null,
                
                  child: Center(
                    child: FittedBox(fit: BoxFit.scaleDown,
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _weekDayHeaders(Color color,BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: _weekdays
        .map(
          (d) => FittedBox(fit: BoxFit.scaleDown,
            child: Text(
              d,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )
        .toList(),
  );
}

List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
