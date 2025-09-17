import 'package:buddy/models/note_model.dart';
import 'package:buddy/providers/notes_provider.dart';
import 'package:buddy/screens/navigation_screen.dart';
import 'package:buddy/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotesHomePreview extends ConsumerWidget {
  const NotesHomePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    return InkWell(
      borderRadius: BorderRadius.circular(15.r),
      onTap: () => NavigationScreen.switchToTab(context, 1),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Text(
              'Notes',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            ..._previewNote(ref, notes, context),
          ],
        ),
      ),
    );
  }

  List<Widget> _previewNote(
    WidgetRef ref,
    List<Note> note,
    BuildContext context,
  ) {
    final preview = note.take(2).toList();

    if (preview.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.r),
          child: Text('Notes is empty'),
        ),
      ];
    }

    return preview.map((notes) {
      return ListTile(
        title: Text(
          notes.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14.sp),
        ),
        subtitle: Row(
          children: [
            Text(
              '${formatDateTime(notes.createdAt)} :',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                notes.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
