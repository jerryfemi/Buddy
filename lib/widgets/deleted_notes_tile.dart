import 'package:buddy/models/deleted_notes_model.dart';
import 'package:buddy/providers/deleted_notes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class DeletedNotesTile extends ConsumerWidget {
  final DeletedNote note;

  const DeletedNotesTile({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = 30 - DateTime.now().difference(note.deletedAt).inDays;
    void onTapTile() {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              ' Recently Deleted Note',
              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20.sp),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 13.w,
              vertical: 10.h,
            ),
            content: Column(mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recently deleted notes can\'t be edited.\nTo edit this note, you\'ll need to restore it.',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(deletedNotesProvider.notifier).restoreNote(note.id);
                  Navigator.pop(context);
                },
                child: Text('restore'),
              ),
            ],
          );
        },
      );
    }

    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            borderRadius: BorderRadius.circular(12.r),
            onPressed: (context) => ref
                .read(deletedNotesProvider.notifier)
                .permanentlyDeleteNote(note.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      key: ValueKey(note.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTapTile,
        child: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ListTile(
            title: Text(
              maxLines: 1,
              note.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            subtitle: Text(
              maxLines: 1,
              note.subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Text(
              '$daysLeft days left',
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 12.sp,fontWeight: FontWeight.w500
              ),
            ),
          ),
        ),
      ),
    );
  }
}
