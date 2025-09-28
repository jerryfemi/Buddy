import 'package:buddy/providers/deleted_notes_provider.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/deleted_notes_tile.dart';
import '../widgets/my_sliver_app_bar.dart';
import '../widgets/search_bar_delegate.dart';

class RecentlyDeletedNotesScreen extends ConsumerStatefulWidget {
  const RecentlyDeletedNotesScreen({super.key});

  @override
  ConsumerState<RecentlyDeletedNotesScreen> createState() =>
      _RecentlyDeletedNotesScreenState();
}

class _RecentlyDeletedNotesScreenState
    extends ConsumerState<RecentlyDeletedNotesScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final deletedNote = ref.watch(deletedNotesProvider);
    // filter notes based on title or plain text content
    final filteredNotes = deletedNote.where((deleted) {
      final searchLower = searchQuery.toLowerCase();
      return deleted.content.toLowerCase().contains(searchLower) ||
          deleted.title.toLowerCase().contains(searchLower);
    }).toList();
    return Scaffold(
      body: CustomScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // notes app bar
          MySliverAppBar(
            leading: null,
            actions: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.exit_to_app,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
            title:'Recently Deleted'
          ),
          deletedNote.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(height: 250.h),
                        Text(
                          'No recently deleted notes',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              :
                // Search bar
                SliverPersistentHeader(
                  pinned: false,
                  delegate: SearchBarDelegate(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final deleted = filteredNotes[index];
              return Padding(
                padding: EdgeInsets.only(
                  left:  context.adaptSize(15.w,tab: 12.w),
                  right:  context.adaptSize(15.w,tab: 12.w),
                  bottom: context.adaptPadding(8.h, tab: 5.h),
                ),
                child: DeletedNotesTile(note: deleted),
              );
            }, childCount: filteredNotes.length),
          ),
        ],
      ),
    );
  }
}
