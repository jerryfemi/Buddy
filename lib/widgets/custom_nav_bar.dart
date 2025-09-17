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
      padding:  EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 18.h),
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          //0xFF17203A
          borderRadius: BorderRadius.circular(25.r),
        ),
        margin: EdgeInsets.only(left: 10.w, right: 10.w, top: 3),
        child: GNav(
          color: Theme.of(context).colorScheme.tertiary,
          activeColor: Theme.of(context).colorScheme.primary,
          padding: EdgeInsets.all(8.r),
          iconSize: 30.sp,
          textStyle: TextStyle(fontFamily: 'Times New Roman', fontSize: 16.sp),
          onTabChange: widget.onTabChanged,
          selectedIndex: widget.selectedIndex,
          tabBackgroundColor: Theme.of(context).colorScheme.secondary,

          gap: 8.sp,
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
