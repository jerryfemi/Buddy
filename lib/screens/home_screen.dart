import 'package:buddy/providers/auth_provider.dart';
import 'package:buddy/screens/user_profile_screen.dart';
import 'package:buddy/utils/responsive_utils.dart';
import 'package:buddy/utils/router.dart';
import 'package:buddy/widgets/custom_drawer.dart';
import 'package:buddy/widgets/home_previews/events_home_preview.dart';
import 'package:buddy/widgets/home_previews/notes_home_preview.dart';
import 'package:buddy/widgets/home_previews/tasks_home_preview.dart';
import 'package:buddy/widgets/my_alert_dialog.dart';
import 'package:buddy/widgets/my_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../widgets/theme_toggle_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _drawer(context),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          MySliverAppBar(
            title: 'Home',
            actions: [
              Builder(
                builder: (context) {
                  return IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: Icon(Icons.menu_rounded),
                  );
                },
              ),
            ],
          ),

          context.isTab ? _tabLayout(context) : _mobileLayout(context),
        ],
      ),
    );
  }
}

// EXTRACTED WIDGETS
Widget _drawer(BuildContext context) {
  return Consumer(
    builder: (context, ref, child) {
      final user = ref.watch(authNotifierProvider);
      return CustomDrawer(
        listTile: ListTile(
          onTap: () {
            if (user == null) {
              showLoginDialog(context);
            } else {
              showSignOutDialog(context, ref);
            }
          },
          leading: Icon(
            user == null ? Icons.login_rounded : Icons.exit_to_app,
            color: Theme.of(context).colorScheme.primary,
            size: context.adaptSize(30.sp, tab: 20.sp),
          ),
          title: Text(
            user == null ? 'Sign in' : 'Sign out',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: context.adaptSize(16.sp, tab: 12.sp),
            ),
          ),
        ),
        onTap1: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        },
        onTap2: null,
        title1: 'Profile',
        title2: 'Theme',
        leading1: IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.primary,
            size: context.adaptSize(30.sp, tab: 20.sp),
          ),
        ),
        leading2: ThemeToggleButton(),
        header: Image.asset(
          'lib/assets/images/buddy_logo.png',
          height: context.adaptSize(150.h, tab: 110.h),
          width: context.adaptSize(150.w, tab: 110.w),
        ),
      );
    },
  );
}

// Tab Layout
Widget _tabLayout(BuildContext context) {
  return SliverToBoxAdapter(
    key: const ValueKey('tab_layout'),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.adaptPadding(24.w, tab: 19.w),
        vertical: 8.h,
      ),
      child: Column(
        children: [
          //Row with Tasks + Notes side by side
          Row(
            children: [
              Expanded(
                child: TasksHomePreview()
                    .animate()
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
                    ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: NotesHomePreview()
                    .animate(delay: 250.ms)
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
                    ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Events full width
          EventsHomePreview()
              .animate(delay: 500.ms)
              .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOutCubic)
              .scaleXY(
                begin: 0.95,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    ),
  );
}

// mobile layout
Widget _mobileLayout(BuildContext context) {
  final List<Widget> previewWidgets = [
    TasksHomePreview(),
    NotesHomePreview(),
    EventsHomePreview(),
  ];

  return SliverList(
    key: const ValueKey('mobile_layout'),
    delegate: SliverChildListDelegate(
      previewWidgets.asMap().entries.map((entry) {
        final index = entry.key;
        final widget = entry.value;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
          child: widget
              .animate(delay: (250 * index).ms)
              .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOutCubic)
              .scaleXY(
                begin: 0.95,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
        );
      }).toList(),
    ),
  );
}

// sign ut dialog
Future<void> showSignOutDialog(BuildContext context, WidgetRef ref) async {
  return showDialog(
    context: context,
    builder: (context) => MyAlertDialog(
      content: 'Are you sure you want to sign out',
      title: Text('Sign out'),
      buttonText: 'Sign Out',
      text: 'cancel',
      onPressed: () async {
        Navigator.of(context).pop();
        await ref.read(authNotifierProvider.notifier).signOut();
      },
    ),
  );
}

// login dialog
Future<void> showLoginDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (dialogContext) => MyAlertDialog(
      content: 'Sign in to keep your Buddy data safe and in sync',
      title: Text('Sign in'),
      buttonText: 'Sign in',
      text: 'cancel',
      onPressed: () {
        Navigator.of(dialogContext).pop();
        context.go(AppRoutes.auth);
      },
    ),
  );
}
