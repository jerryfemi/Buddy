import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/theme_preference_provider.dart';

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
          ref
              .read(themeProvider.notifier)
              .setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
        },
        constraints: BoxConstraints(),
        padding: EdgeInsets.zero,
        icon: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nights_stay,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          size: context.adaptSize(30.sp, tab: 20.sp),
        ),
      ),
    );
  }
}
