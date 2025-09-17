import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomDrawer extends StatelessWidget {
  final void Function()? onTap1;
  final void Function()? onTap2;

  const CustomDrawer({super.key, required this.onTap1, required this.onTap2});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Text(
                'Calendar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.calendar_view_month_outlined,
                      size: 26.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Go To',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 16.sp,
                      ),
                    ),
                    onTap: onTap1,
                  ),
                  Divider(
                    height: 0,
                    indent: 35.w,
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.5),
                  ),
                  ListTile(
                    onTap: onTap2,
                    leading: Icon(
                      Icons.calendar_month_rounded,
                      size: 26.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Year',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
