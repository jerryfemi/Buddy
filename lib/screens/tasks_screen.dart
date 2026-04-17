import 'package:buddy/providers/tasks_provider.dart';
import 'package:buddy/utils/responsive_utils.dart';
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
  static const double _collapsedSnap = 0.58;
  static const double _expandedSnap = 0.8;

  late final AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  ProviderSubscription? _subscription;

  @override

  void initState() {
    super.initState();
    final initialFraction = ref.read(tasksProvider.notifier).completionFraction;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: initialFraction,
    );

    _subscription = ref.listenManual(tasksProvider, (_, _) {
      final newFraction = ref.read(tasksProvider.notifier).completionFraction;
      if (_controller.value != newFraction) {
        _controller.animateTo(newFraction, curve: Curves.easeInOut);
      }
    });
  }


  @override
  void dispose() {
    _subscription?.close();
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // task dialog
  void openTaskDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 190),
        reverseDuration: Duration(milliseconds: 170),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: _collapsedSnap,
          minChildSize: _collapsedSnap,
          maxChildSize: _expandedSnap,
          snap: true,
          snapSizes: const [_collapsedSnap, _expandedSnap],
          builder: (context, scrollController) =>
              TaskDialog(controller: scrollController),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final sortedTasks = [

      ...tasks.where((t) => !t.isCompleted),
      ...tasks.where((t) => t.isCompleted),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasks',
        onPressed: () => openTaskDialog(context),
        shape: CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
                    minExtentClampL: context.adaptSize(80.h, tab: 60.h),
                    minExtentClampU: context.adaptSize(90.h, tab: 70.h),
                    maxExtentClampL: context.adaptSize(260.h, tab: 230.h),
                    maxExtentClampU: context.adaptSize(290.h, tab: 260.h),
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
                              bottom: 5.h,
                              left: 12.w,
                              right: 12.w,
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
