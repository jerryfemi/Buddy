import 'dart:ui';

import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class TasksHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double percent;
  final double screenHeight;
  final double maxExtentClampL;
  final double maxExtentClampU;
  final double minExtentClampL;
  final double minExtentClampU;

  TasksHeaderDelegate({
    required this.percent,
    required this.screenHeight,
    required this.maxExtentClampL,
    required this.maxExtentClampU,
    required this.minExtentClampL,
    required this.minExtentClampU,
  });

  @override
  double get minExtent {
    final double min = 0.18 * screenHeight;

    return min.clamp(minExtentClampL, minExtentClampU).floorToDouble();
  }

  @override
  double get maxExtent {
    final double max = 0.4 * screenHeight;
    return max.clamp(maxExtentClampL, maxExtentClampU).floorToDouble();
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final clampedShrinkOffset = shrinkOffset.clamp(0.0, maxExtent - minExtent);
    final progress = (clampedShrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );
    final curved = Curves.easeInOut.transform(progress);

    final double titleFontSize = lerpDouble(
      context.adaptSize(30.sp, tab: 24.sp),
      context.adaptSize(22.sp, tab: 16.sp),
      curved,
    )!.floorToDouble();
    final double indicatorRadius = lerpDouble(
      context.adaptSize(88.w, tab: 70.w),

      context.adaptSize(35.w, tab: 15.w),
      curved,
    )!.floorToDouble();
    final double lineWidth = lerpDouble(
      context.adaptSize(15.w, tab: 11.w),
      context.adaptSize(8.w, tab: 4.w),
      curved,
    )!.floorToDouble();
    final double spacing = lerpDouble(0, 0, curved)!.floorToDouble();
    final double topPadding = lerpDouble(40.h, 2.h, curved)!.floorToDouble();
    final double centerFontSize = lerpDouble(
      context.adaptSize(28.sp, tab: 21.sp),
      context.adaptSize(8.sp, tab: 4.sp),
      curved,
    )!;
    final double titleTranslateY = lerpDouble(0.0, -6.h, curved)!;

    final Axis direction = progress < 0.4 ? Axis.vertical : Axis.horizontal;

    final double available = maxExtent - shrinkOffset;
    final double extraStretch = (available - maxExtent).clamp(
      0.0,
      double.infinity,
    );
    final double stretchScale = 1.0 + (extraStretch / 240.0).clamp(0.0, 0.12);

    return Material(
      elevation: 1.6,
      child: ClipRect(
        child: Transform.scale(
          scale: stretchScale,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: topPadding, left: 20.w, right: 16.w),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.elasticIn,
              child: Flex(
                key: ValueKey(direction),
                direction: direction,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: direction == Axis.vertical
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, titleTranslateY),
                    child: Text(
                      'Tasks',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: titleFontSize,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: direction == Axis.vertical ? spacing : 0,
                    width: direction == Axis.horizontal ? spacing : 0,
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: direction == Axis.vertical
                          ? Alignment.center
                          : Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: CircularPercentIndicator(
                          radius: indicatorRadius,
                          percent: percent,
                          animation: true,
                          animateFromLastPercent: true,
                          lineWidth: lineWidth,
                          circularStrokeCap: CircularStrokeCap.round,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          progressColor: Theme.of(context).colorScheme.primary,
                          center: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${(percent * 100).round()}%',
                              style: TextStyle(
                                fontSize: centerFontSize,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.93),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant TasksHeaderDelegate oldDelegate) {
    return oldDelegate.percent != percent;
  }
}
