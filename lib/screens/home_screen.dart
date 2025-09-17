import 'package:buddy/providers/theme_preference_provider.dart';
import 'package:buddy/widgets/home_previews/events_home_preview.dart';
import 'package:buddy/widgets/home_previews/notes_home_preview.dart';
import 'package:buddy/widgets/home_previews/tasks_home_preview.dart';
import 'package:buddy/widgets/my_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> previewWidgets = [
      Padding(
        padding: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 8.w),
        child: TasksHomePreview(),
      ),
      Padding(
        padding: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 8.w),
        child: NotesHomePreview(),
      ),
      Padding(
        padding: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 8.w),
        child: EventsHomePreview(),
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          MySliverAppBar(
            title: Text(
              'Home',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
            ),
            actions: [ThemeToggleButton()],
            leading: null,
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              previewWidgets.asMap().entries.map((entry) {
                final index = entry.key;
                final widget = entry.value;
                return widget
                    .animate(delay: (250 * index).ms)
                    .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
                    .slideY(
                      begin: 0.3,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .scaleXY(
                      begin: 0.95,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeToggleButton extends ConsumerStatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  ConsumerState<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends ConsumerState<ThemeToggleButton> {
  late bool isDark;
  late ProviderSubscription<ThemeMode> _sub;

  @override
  void initState() {
    super.initState();
    final theme = ref.read(themeProvider);
    isDark = theme == ThemeMode.dark;

    // listen for changes
    _sub = ref.listenManual<ThemeMode>(themeProvider, (previous, next) {
      setState(() {
        isDark = next == ThemeMode.dark;
      });
    });
  }

  // dispose
  @override
  void dispose() {
    super.dispose();
    _sub.close();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 140),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        );
      },
      child: IconButton(
        key: ValueKey(isDark),
        onPressed: () {
          HapticFeedback.selectionClick();
          ref
              .read(themeProvider.notifier)
              .setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
        },
        icon: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nights_stay,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
