import 'package:buddy/providers/deleted_notes_provider.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:buddy/models/deleted_notes_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'dart:async';

import '../widgets/deleted_notes_tile.dart';
import '../widgets/my_sliver_app_bar.dart';
import '../widgets/search_bar_delegate.dart';

class DeletedNotesSearchQueryNotifier extends StateNotifier<String> {
  DeletedNotesSearchQueryNotifier() : super('');

  void updateQuery(String value) {
    state = value;
  }
}

final deletedNotesSearchQueryProvider =
    StateNotifierProvider.autoDispose<DeletedNotesSearchQueryNotifier, String>(
      (ref) => DeletedNotesSearchQueryNotifier(),
    );

typedef FilteredDeletedNotesResult = ({
  List<DeletedNote> items,
  bool hasAnyNotes,
});

final filteredDeletedNotesProvider =
    Provider.autoDispose<FilteredDeletedNotesResult>((ref) {
      final deletedNotes = ref.watch(deletedNotesProvider);
      final searchQuery = ref
          .watch(deletedNotesSearchQueryProvider)
          .toLowerCase();

      final items = searchQuery.isEmpty
          ? deletedNotes
          : deletedNotes.where((deleted) {
              return deleted.content.toLowerCase().contains(searchQuery) ||
                  deleted.title.toLowerCase().contains(searchQuery);
            }).toList();

      return (items: items, hasAnyNotes: deletedNotes.isNotEmpty);
    });

class RecentlyDeletedNotesScreen extends ConsumerStatefulWidget {
  const RecentlyDeletedNotesScreen({super.key});

  @override
  ConsumerState<RecentlyDeletedNotesScreen> createState() =>
      _RecentlyDeletedNotesScreenState();
}

class _RecentlyDeletedNotesScreenState
    extends ConsumerState<RecentlyDeletedNotesScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredDeletedNotesProvider);
    final filteredNotes = filtered.items;

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
                  Icons.close,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
            title: 'Recently Deleted',
          ),
          !filtered.hasAnyNotes
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
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        ref
                            .read(deletedNotesSearchQueryProvider.notifier)
                            .updateQuery(value);
                      });
                    },
                  ),
                ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final deleted = filteredNotes[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: context.adaptSize(15.w, tab: 12.w),
                  right: context.adaptSize(15.w, tab: 12.w),
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
