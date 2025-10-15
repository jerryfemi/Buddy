import 'package:buddy/widgets/mini_month.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class YearGrid extends StatelessWidget {
  final int year;
  final ValueChanged<int> onMonthSelected;

  const YearGrid({
    super.key,
    required this.year,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        return InkWell(
          onTap: () => onMonthSelected(month),
          child: Padding(
            padding: EdgeInsets.all(0.r),
            child: Card(
              elevation: 0,
              child: Column(
                children: [
                   Text(
                      DateFormat.MMMM().format(DateTime(year, month, 1)),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: MiniMonth(year: year, month: month),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
