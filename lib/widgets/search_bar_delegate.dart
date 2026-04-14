import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double _maxExtentHeight = 50;
  final void Function(String)? onChanged;

  SearchBarDelegate({required this.onChanged});

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => _maxExtentHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // Move search bar up as it collapses
    final offsetY = -progress * _maxExtentHeight;

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Opacity(
        opacity: 1 - progress,
        child: Padding(
          padding:  EdgeInsets.only(left: 16.w, right: 16.w),
          child: CupertinoSearchTextField(onChanged: onChanged),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SearchBarDelegate oldDelegate) => oldDelegate.onChanged != onChanged;
}
