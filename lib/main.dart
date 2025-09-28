import 'package:buddy/firebase/auth/auth_gate.dart';
import 'package:buddy/models/calendar_event_model.dart';
import 'package:buddy/models/deleted_notes_model.dart';
import 'package:buddy/models/previous_events_model.dart';
import 'package:buddy/models/task_model.dart';
import 'package:buddy/models/theme_model.dart';
import 'package:buddy/providers/theme_preference_provider.dart';
import 'package:buddy/screens/navigation_screen.dart';
import 'package:buddy/services/notification_services.dart';
import 'package:buddy/themes/dark_theme.dart';
import 'package:buddy/themes/light_mode.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';

import 'models/note_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // lock the app orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // FIREBASE INIT()
  await Firebase.initializeApp();

  // HIVE INIT()
  await Hive.initFlutter();

  // NOTIFICATIONS SERVICE INIT()
  if (!kIsWeb) {
    await NotificationService.init();
  }

  // register adapters
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(CalendarEventAdapter());
  Hive.registerAdapter(PriorityAdapter());
  Hive.registerAdapter(DeletedNoteAdapter());
  Hive.registerAdapter(PreviousEventsAdapter());
  Hive.registerAdapter(ThemePreferenceAdapter());

  // open hive boxes
  await Hive.openBox<Note>('notesBox');
  await Hive.openBox<Task>('tasksBox');
  await Hive.openBox<CalendarEvent>('eventsBox');
  await Hive.openBox<DeletedNote>('deletedNotesBox');
  await Hive.openBox<PreviousEvents>('previousEventsBox');
  await Hive.openBox<ThemePreference>('themeBox');

  runApp(
    ProviderScope(
      child:
          // DevicePreview(
          //   enabled: !kReleaseMode,
          //   defaultDevice: Devices.ios.iPhone15Pro,
          //   builder: (context) =>
          const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          home: AuthGate(),
          debugShowCheckedModeBanner: false,
          title: 'Buddy',
          themeMode: theme,
          darkTheme: darkMode,
          theme: lightMode,
          locale: DevicePreview.locale(context),
          localizationsDelegates: [FlutterQuillLocalizations.delegate],
          builder: (context, child) {
            child = DevicePreview.appBuilder(context, child);
            final theme = Theme.of(context);

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                systemNavigationBarColor: theme.scaffoldBackgroundColor,
                systemNavigationBarIconBrightness:
                    theme.brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}
