import 'package:buddy/providers/tasks_provider.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';

class TaskDialog extends ConsumerStatefulWidget {
  final ScrollController controller;

  const TaskDialog({super.key, required this.controller});

  @override
  ConsumerState<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends ConsumerState<TaskDialog> {
  Priority? _selectedPriority;
  final TextEditingController _titleController = TextEditingController();
  bool _hasReminder = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  DateTime? get _reminderDateTime {
    if (_selectedDate == null) return null;
    final time = _selectedTime ?? TimeOfDay(hour: 0, minute: 0);
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30.r),
          topLeft: Radius.circular(30.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ListView(
            controller: widget.controller,
            children: [
              Divider(
                indent: 90.w,
                endIndent: 90.w,
                height: 16.h,
                thickness: 4.h,
                color: Theme.of(context).colorScheme.secondary,
              ),
              Center(
                child: Text(
                  'Create a task',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: context.adaptSize(18.h, tab: 14.h),
                  ),
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                'Task title',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: context.adaptSize(16.sp, tab: 12.sp),
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.secondary,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  hintText: 'title',
                  hintStyle: TextStyle(
                    fontSize: context.adaptSize(13.sp, tab: 10.sp),
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Priority',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: context.adaptSize(16.sp, tab: 12.sp),
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              SizedBox(height: context.adaptSize(5.h, tab: 10.h)),
              Wrap(
                spacing: 15.w,
                children: Priority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  final color = _getPriorityColor(priority);
                  return ChoiceChip(
                    label: Text(
                      priority.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: color.withValues(alpha: 0.8),
                    labelPadding: EdgeInsets.all(5.r),
                    backgroundColor: color.withValues(alpha: 0.1),
                    onSelected: (value) {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    },
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: color.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications,
                        size: context.isTab ? 18.sp : null,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 5.h),
                      Text(
                        'Add reminder',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: context.adaptSize(16.sp, tab: 12.sp),
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  // reminder switch button
                  CupertinoSwitch(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    value: _hasReminder,
                    onChanged: (val) {
                      setState(() {
                        _hasReminder = val;
                        if (!val) {
                          _selectedDate = null;
                          _selectedTime = null;
                        }
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // show dateTime picker if user enables
              if (_hasReminder)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Container(
                          decoration: ShapeDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          child: TextButton.icon(
                            icon: Icon(
                              Icons.calendar_today_rounded,
                              size: context.isTab ? 11.sp : null,
                            ),
                            label: Text(
                              _selectedDate != null
                                  ? DateFormat(
                                      'MMM d,  yyy',
                                    ).format(_selectedDate!)
                                  : 'Select date',
                              style: TextStyle(
                                fontSize: context.isTab ? 10.sp : null,
                              ),
                            ),
                            onPressed: _pickDate,
                          ),
                        ),
                        SizedBox(width: 10.h),
                        Container(
                          decoration: ShapeDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          child: TextButton.icon(
                            icon: Icon(
                              Icons.access_time_rounded,
                              size: context.isTab ? 11.sp : null,
                            ),
                            label: Text(
                              _selectedTime?.format(context) ?? 'Select time',
                              style: TextStyle(
                                fontSize: context.isTab ? 10.sp : null,
                              ),
                            ),
                            onPressed: _pickTime,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 25.h),

              InkWell(
                onTap: () {
                  if (_titleController.text.trim().isEmpty) return;
                  ref
                      .read(tasksProvider.notifier)
                      .createTask(
                        title: _titleController.text.trim(),
                        priority: _selectedPriority ?? Priority.low,
                        reminderTime: _hasReminder ? _reminderDateTime : null,
                      );
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.adaptSize(22.w, tab: 15.w),
                    vertical: context.adaptSize(18.w, tab: 10.w),
                  ),
                  margin: EdgeInsets.only(bottom: 0.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Center(
                    child: Text('Add Task', style: TextStyle(fontSize: 11.sp)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// get priority color
Color _getPriorityColor(Priority priority) {
  switch (priority) {
    case Priority.low:
      return Colors.green;
    case Priority.medium:
      return Colors.amber;
    case Priority.high:
      return Colors.red;
  }
}
