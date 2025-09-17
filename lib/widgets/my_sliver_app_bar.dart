import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MySliverAppBar extends StatelessWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;

  const MySliverAppBar({
    super.key,
    required this.title,
    required this.actions,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(automaticallyImplyLeading: false,
      leading:leading,
      actions: actions,
      pinned: true,
      expandedHeight: 100.h,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16.w, bottom: 8.h),
        title: title,
      ),
    );
  }
}
