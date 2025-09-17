import 'package:buddy/providers/tasks_provider.dart';
import 'package:buddy/widgets/task_dialog.dart';
import 'package:buddy/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/task_app_bar.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final initialFraction = ref.read(tasksProvider.notifier).completionFraction;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: initialFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // task dialog
  void openTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.58,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (context, scrollController) =>
              TaskDialog(controller: scrollController),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the provider to trigger animations as a side-effect.
    ref.listen(tasksProvider, (_, _) {
      final newFraction = ref.read(tasksProvider.notifier).completionFraction;
      // Animate the controller's value from its current value to the new fraction.
      _controller.animateTo(newFraction, curve: Curves.easeInOut);
    });

    final tasks = ref.watch(tasksProvider);
    final sortedTasks = [
      ...tasks.where((t) => !t.isCompleted),
      ...tasks.where((t) => t.isCompleted),
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasks',
        onPressed: () => openTaskDialog(context),
        shape: CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomScrollView(
              physics: BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              controller: _scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: TasksHeaderDelegate(
                    percent: _controller.value,
                    screenHeight: MediaQuery.of(context).size.height,
                  ),
                ),
                SliverPadding(padding: EdgeInsets.only(bottom: 20.h)),
                tasks.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(height: 100.h),
                              Text(
                                'Create your personal tasks.',
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
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final task = sortedTasks[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 8.h,
                              left: 20.w,
                              right: 20.w,
                            ),
                            child: TaskTile(
                              task: task,
                              onChanged: (_) {
                                ref
                                    .read(tasksProvider.notifier)
                                    .toggleTask(task.id);
                              },
                            ),
                          );
                        }, childCount: tasks.length),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
