import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class CustomNavBar extends StatefulWidget {
  final void Function(int)? onTabChanged;
  final int selectedIndex;

  const CustomNavBar({
    super.key,
    required this.onTabChanged,
    required this.selectedIndex,
  });

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12.h,
      ),
      child: Container(
        padding: EdgeInsets.all(context.adaptPadding(10.r,tab: 6.r)),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          //0xFF17203A
          borderRadius: BorderRadius.circular(25.r),
        ),
        margin: EdgeInsets.only(
          left: context.adaptPadding(10.w, tab: 60.w),
          right: context.adaptPadding(10.w, tab: 60.w),
          top: 3,
        ),
        child: GNav(
          color: Theme.of(context).colorScheme.tertiary,
          activeColor: Theme.of(context).colorScheme.primary,
          padding: EdgeInsets.all(8.r),
          iconSize: context.isMobile ? 30.sp : 45,
          textStyle: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: context.adaptSize(16.sp, tab: 25),
          ),
          onTabChange: widget.onTabChanged,
          selectedIndex: widget.selectedIndex,
          tabBackgroundColor: Theme.of(context).colorScheme.secondary,

          gap: context.adaptSize(8.w, tab: 8),
          tabs: const [
            GButton(icon: Icons.home_rounded, text: 'Home'),
            GButton(icon: Icons.book_outlined, text: 'Notes'),
            GButton(icon: Icons.check_circle_outline, text: 'Tasks'),
            GButton(icon: Icons.date_range_outlined, text: 'Events'),
          ],
        ),
      ),
    );
  }
}
