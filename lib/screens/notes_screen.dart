import 'dart:async';

import 'package:buddy/providers/notes_provider.dart';
import 'package:buddy/utils/router.dart';
import 'package:buddy/widgets/my_sliver_app_bar.dart';
import 'package:buddy/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:go_router/go_router.dart';

import '../widgets/search_bar_delegate.dart';
import 'package:buddy/models/note_model.dart';

class NotesSearchQueryNotifier extends StateNotifier<String> {
  NotesSearchQueryNotifier() : super('');

  void updateQuery(String value) {
    state = value;
  }
}

final notesSearchQueryProvider =
    StateNotifierProvider.autoDispose<NotesSearchQueryNotifier, String>(
      (ref) => NotesSearchQueryNotifier(),
    );

typedef FilteredNotesResult = ({List<Note> items, bool hasAnyNotes});

final filteredNotesProvider = Provider.autoDispose<FilteredNotesResult>((ref) {
  final notes = ref.watch(notesProvider);
  final searchQuery = ref.watch(notesSearchQueryProvider).toLowerCase();

  final filteredNotes = notes.where((note) {
    return note.content.toLowerCase().contains(searchQuery) ||
        note.title.toLowerCase().contains(searchQuery);
  }).toList();
  filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return (items: filteredNotes, hasAnyNotes: notes.isNotEmpty);
});

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends ConsumerState<NotesScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredNotesProvider);
    final filteredNotes = filtered.items;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes',
        shape: CircleBorder(),
        onPressed: () => context.push(AppRoutes.editNote),
        child: Icon(Icons.add, color: Colors.white),
      ),

      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // app bar
          _appBar(context),
          !filtered.hasAnyNotes
              ? // empty state
                _emptyState(context)
              :
                // Search bar
                SliverPersistentHeader(
                  pinned: false,
                  delegate: SearchBarDelegate(
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        ref
                            .read(notesSearchQueryProvider.notifier)
                            .updateQuery(value);
                      });
                    },
                  ),
                ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final note = filteredNotes[index];
              return Padding(
                padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 4.h),
                child: NoteTile(note: note),
              );
            }, childCount: filteredNotes.length),
          ),
        ],
      ),
    );
  }
}

// EXTRACTED WIDGETS
Widget _appBar(BuildContext context) {
  return MySliverAppBar(
    leading: null,
    actions: [
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'deleted') {
            context.push(AppRoutes.recentlyDeletedNotes);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'deleted',
            child: Text(
              'Recently Deleted',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ],
    title: 'Notes',
  );
}

Widget _emptyState(BuildContext context) {
  return SliverToBoxAdapter(
    child: Center(
      child: Column(
        children: [
          SizedBox(height: 250.h),
          Text(
            'Create your personal notes.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 13.sp,
            ),
          ),
          Text(
            'Tap the plus button to get started.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    ),
  );
}
