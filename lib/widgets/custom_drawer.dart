import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomDrawer extends StatelessWidget {
  final void Function()? onTap1;
  final void Function()? onTap2;
  final Widget header;
  final String title1;
  final String title2;
  final Widget leading1;
  final Widget leading2;
  final Widget? listTile;

  const CustomDrawer({
    super.key,
    required this.onTap1,
    required this.onTap2,
    required this.title1,
    required this.title2,
    required this.leading1,
    required this.leading2,
    required this.header,
    this.listTile,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 20.r),
          child: Column(
            children: [
              header,
              SizedBox(height: 20.h),

              ListTile(
                leading: leading1,
                title: Text(
                  title1,
                  style: TextStyle(
                    fontSize: context.adaptSize(16.sp,tab:12.sp),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: onTap1,
              ),

              ListTile(
                onTap: onTap2,
                leading: leading2,
                title: Text(
                  title2,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: context.adaptSize(16.sp,tab:12.sp),
                  ),
                ),
              ),

              const Spacer(),

              if (listTile != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 20.r),
                  child: listTile!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
