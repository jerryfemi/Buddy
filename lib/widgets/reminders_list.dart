import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RemindersList extends StatelessWidget {
  final List<int> reminders;
  final Function(int) onRemove;

  const RemindersList({
    super.key,
    required this.reminders,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) return const SizedBox.shrink();

    return Column(
      children: reminders.map((r) {
        final label = r >= 60
            ? "${r ~/ 60} hr${r >= 120 ? 's' : ''} before"
            : "$r min before";

        return Column(mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onRemove(r),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
          ],
        );
      }).toList(),
    );
  }
}

class ReminderOptions {
  static const options = <int>[10, 20, 30, 60, 120];

  // list of popup menu items
  static List<PopupMenuItem<int>> get popupItems => [
    ...options.map(
      (r) => PopupMenuItem(
        value: r,
        child: Text(
          r >= 60
              ? '${r / 60} hr${r >= 120 ? 's' : ''} before'
              : '$r min before',
        ),
      ),
    ),
  ];
}

class AddReminderButton extends StatelessWidget {
  final Function(int) onAdd;

  const AddReminderButton({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await showMenu<int>(
          context: context,
          position: const RelativeRect.fromLTRB(100, 400, 100, 100),
          items: ReminderOptions.popupItems,
        );

        if (selected == null) return;

        onAdd(selected);
      },
      child: Text(
        'Add Reminder',
        style: TextStyle(
          fontSize: 15.sp,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
