import 'package:buddy/widgets/year_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class YearViewScreen extends StatefulWidget {
  final int year;
  final void Function(DateTime) onMonthSelected;

  const YearViewScreen({
    super.key,
    required this.year,
    required this.onMonthSelected,
  });

  @override
  State<YearViewScreen> createState() => _YearViewScreenState();
}

class _YearViewScreenState extends State<YearViewScreen> {
  static const int baseYear = 1970; // base year for page mapping
  late PageController _pageController;
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.year;
    _pageController = PageController(initialPage: widget.year - baseYear);
  }

  // go to previous year
  void _goToPreviousYear() {
    _pageController.previousPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // go to next year
  void _goToNextYear() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$_currentYear",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _goToPreviousYear,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          IconButton(
            onPressed: _goToNextYear,
            icon: Icon(Icons.arrow_forward_ios_rounded),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _currentYear = baseYear + page; // keeps AppBar year in sync
          });
        },
        itemBuilder: (context, pageIndex) {
          final year = baseYear + pageIndex;
          return ClipRRect(
            child: YearGrid(
              year: year,
              onMonthSelected: (month) {
                final selectedDate = DateTime(year, month, 1);
                widget.onMonthSelected(selectedDate);
                Navigator.pop(context, selectedDate);
              },
            ),
          );
        },
      ),
    );
  }
}
