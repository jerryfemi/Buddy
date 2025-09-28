import 'package:buddy/providers/notes_provider.dart';
import 'package:buddy/screens/edit_note_screen.dart';
import 'package:buddy/screens/recently_deleted_notes_screen.dart';
import 'package:buddy/transition_class/dart/app_navigator.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:buddy/widgets/my_sliver_app_bar.dart';
import 'package:buddy/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/search_bar_delegate.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends ConsumerState<NotesScreen> {
  late String _searchQuery = '';

  void addNewNote(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditNotesScreen(existingNote: null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    // filter notes based on title or plain text content
    final filteredNotes = notes.where((note) {
      final searchLower = _searchQuery.toLowerCase();
      return note.content.toLowerCase().contains(searchLower) ||
          note.title.toLowerCase().contains(searchLower);
    }).toList();
    filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes',
        shape: CircleBorder(),
        onPressed: () {
          AppNavigator.push(
            context,
            EditNotesScreen(existingNote: null),
            type: TransitionType.fadeScale,
          );
        },
        child: Icon(Icons.add, color: Colors.white),
      ),

      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // notes app bar
          MySliverAppBar(
            leading: null,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'deleted') {
                    AppNavigator.push(
                      context,
                      RecentlyDeletedNotesScreen(),
                      type: TransitionType.cupertino,
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'deleted',
                    child: Text(
                      'Recently Deleted',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            title: 'Notes',
          ),
          notes.isEmpty
              ? SliverToBoxAdapter(
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
                )
              :
                // Search bar
                SliverPersistentHeader(
                  pinned: false,
                  delegate: SearchBarDelegate(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final note = filteredNotes[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: 12.w,
                  right: 12.w,
                  bottom: 4.h,
                ),
                child: NoteTile(note: note),
              );
            }, childCount: filteredNotes.length),
          ),
        ],
      ),
    );
  }
}
