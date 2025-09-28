import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MySliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const MySliverAppBar({
    super.key,
    required this.title,
    required this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      actions: actions,
      centerTitle: false,
      pinned: true,collapsedHeight: context.isTab? 50.h:null,
      expandedHeight: 100.h,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16.w, bottom: 8.h),
        title: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: context.adaptSize(22.sp, tab: 17.sp),
            ),
          ),
        ),
      ),
    );
  }
}
