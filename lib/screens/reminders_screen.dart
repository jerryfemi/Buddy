import 'package:buddy/screens/year_view_screen.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:buddy/widgets/custom_drawer.dart';
import 'package:buddy/widgets/event_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/add_events_sheet.dart';
import '../widgets/calendar_sliver_persistent_header.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  void openAddEventsDialog() {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: context.adaptSize(0.6, tab: 0.5),
        minChildSize: 0.37,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return AddEventSheet(scrollController: scrollController);
        },
      ),
    );
  }

  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: openAddEventsDialog,
        shape: CircleBorder(),
        child: Icon(Icons.add, color: Colors.white),
      ),
      drawer: CustomDrawer(
        onTap1: () async {
          // open date picker
          Navigator.pop(context);
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDate: _focusedDay,
          );
          if (picked != null) {
            setState(() {
              _focusedDay = picked;
              _selectedDay = picked;
            });
          }
        },
        onTap2: () async {
          // open year view screen
          Navigator.pop(context);
          final pickedMonth = await Navigator.of(context, rootNavigator: true)
              .push<DateTime>(
                MaterialPageRoute(
                  builder: (context) => YearViewScreen(
                    onMonthSelected: (date) {},
                    year: _focusedDay.year,
                  ),
                ),
              );
          if (pickedMonth != null) {
            setState(() {
              _focusedDay = pickedMonth;
              _selectedDay = pickedMonth;
            });
          }
        },
        header: Text(
          'Calendar',
          style: TextStyle(
            fontSize: context.adaptSize(20.sp, tab: 16.sp),
            fontWeight: FontWeight.bold,
          ),
        ),
        title1: 'Go To',
        title2: 'Year',
        leading1: Icon(
          Icons.calendar_view_month_outlined,
          size: context.adaptSize(26.sp,tab: 20.sp),
          color: Theme.of(context).colorScheme.primary,
        ),
        leading2: Icon(
          Icons.calendar_month,
          size: context.adaptSize(26.sp,tab: 20.sp),
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxCalendarHeight = (constraints.maxHeight * 0.95);
            final double minCalendarHeight = 155.h;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              controller: _scrollController,
              slivers: [
                // Shrinkable Calendar Header
                CalendarSliver(
                  selectedDay: _selectedDay,
                  onDaySelected: (day) {
                    setState(() {
                      _selectedDay = day;
                    });

                    // when a date is tapped, scroll down a bit so events show
                    Future.delayed(Duration(milliseconds: 100), () {
                      _scrollController.animateTo(
                        170.h,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
                  focusedDay: _focusedDay,
                  onFocusedDayChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  maxHeight: maxCalendarHeight,
                  minHeight: minCalendarHeight,
                ),
                ////
                SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      Divider(
                        color: Theme.of(context).colorScheme.secondary,
                        height: 30.h,
                        thickness: 6,
                        radius: BorderRadius.circular(10.r),
                      ),
                    ],
                  ),
                ),
                // Events List
                EventsSliver(selectedDay: _selectedDay),
              ],
            );
          },
        ),
      ),
    );
  }
}
