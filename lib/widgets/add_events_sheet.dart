import 'package:buddy/utils/responsive_utils.dart';
import 'package:buddy/widgets/reminders_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../providers/calendar_event_provider.dart';

class AddEventSheet extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const AddEventSheet({super.key, this.scrollController});

  @override
  ConsumerState<AddEventSheet> createState() => _AddEventBottomSheetState();
}

class RepeatRules {
  static const options = <String>[
    'Never',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  static List<DropdownMenuItem<String>> get popDownItems => options
      .map(
        (r) => DropdownMenuItem(
          value: r,
          child: Text(r, style: TextStyle(color: Colors.grey.shade600)),
        ),
      )
      .toList();
}

class _AddEventBottomSheetState extends ConsumerState<AddEventSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isAllDay = false;
  DateTime _startDateTime = DateTime.now();
  DateTime _endDateTime = DateTime.now().add(const Duration(hours: 1));
  final List<int> _reminders = [];
  late String _repeatRule = 'Never';

  void addReminders(int value) {
    setState(() => _reminders.add(value));
  }

  void removeReminders(int value) {
    setState(() => _reminders.remove(value));
  }

  void _toggleAllDay(bool val) {
    setState(() {
      _isAllDay = val;
      if (val) {
        _startDateTime = DateTime(
          _startDateTime.year,
          _startDateTime.month,
          _startDateTime.day,
        );
        _endDateTime = DateTime(
          _startDateTime.year,
          _startDateTime.month,
          _startDateTime.day,
          23,
          59,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30.r),
        topRight: Radius.circular(30.r),
      ),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,

        child: ListView(
          controller: widget.scrollController,
          padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  "New Event",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: context.adaptSize(18.sp, tab: 14.sp),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.blue),
                  onPressed: _saveEvent,
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Title
            TextField(
              controller: _titleController,
              decoration: _inputDecoration(context, 'title'),
            ),
            SizedBox(height: 16.h),

            // All day toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "All day",
                  style: TextStyle(
                    fontSize: context.adaptSize(14.sp, tab: 12.sp),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                CupertinoSwitch(
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  value: _isAllDay,
                  onChanged: _toggleAllDay,
                ),
              ],
            ),
            Divider(color: Theme.of(context).colorScheme.secondary),

            // Start
            _buildDateTimeRow("Start", _startDateTime, (picked) {
              setState(() {
                if (picked != null) _startDateTime = picked;
                if (_isAllDay) _endDateTime = picked!;
              });
            }),

            // End
            _buildDateTimeRow("End", _endDateTime, (picked) {
              setState(() {
                if (picked != null) _endDateTime = picked;
              });
            }, isEndDate: true),
            Divider(color: Theme.of(context).colorScheme.secondary),

            // Reminders
            RemindersList(reminders: _reminders, onRemove: removeReminders),
            AddReminderButton(onAdd: addReminders),
            Divider(color: Theme.of(context).colorScheme.secondary),

            // Repeat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Repeat",
                  style: TextStyle(
                    fontSize: context.adaptSize(14.sp, tab: 12.sp),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                DropdownButton<String>(
                  value: _repeatRule,
                  underline: const SizedBox(),
                  items: RepeatRules.popDownItems,
                  onChanged: (val) => setState(() => _repeatRule = val!),
                ),
              ],
            ),
            Divider(color: Theme.of(context).colorScheme.secondary),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 1,
              decoration: _inputDecoration(context, 'description'),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      filled: true,
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.tertiary,
        fontSize: context.adaptSize(13.sp, tab: 11.sp),
      ),
      fillColor: Theme.of(context).colorScheme.secondary,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
      ),
      hintText: hint,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildDateTimeRow(
    String label,
    DateTime value,
    Function(DateTime?) onPicked, {
    bool isEndDate = false,
  }) {
    final bool isDisabled = _isAllDay && isEndDate;

    return InkWell(
      onTap: isDisabled
          ? null
          : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date == null) return;

              if (_isAllDay) {
                DateTime newDate = DateTime(date.year, date.month, date.day);
                if (!isEndDate) _endDateTime = newDate;
                onPicked(newDate);
              } else {
                if (!mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(value),
                );
                if (time == null) return;

                final newDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
                onPicked(newDateTime);
              }
            },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? Colors.grey : null,
                fontSize: context.adaptSize(12.sp, tab: 10.sp),
              ),
            ),
            Text(
              _isAllDay
                  ? DateFormat("MMM d, yyyy").format(value)
                  : DateFormat("MMM d, yyyy  h:mm a").format(value),
              style: TextStyle(
                fontSize: context.adaptSize(12.sp, tab: 10.sp),
                color: isDisabled
                    ? Theme.of(context).colorScheme.tertiary
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveEvent() {
    if (_titleController.text.trim().isEmpty) return;
    ref
        .read(eventsProvider.notifier)
        .addEvent(
          title: _titleController.text.trim(),
          startDateTime: _startDateTime,
          endDateTime: _endDateTime,
          description: _descriptionController.text.trim(),
          isAllDay: _isAllDay,
          reminders: _reminders,
          repeatRule: _repeatRule.toLowerCase(),
        );
    Navigator.pop(context);
  }
}
