import 'package:buddy/providers/auth_provider.dart';
import 'package:buddy/screens/login_or_register_screen.dart';
import 'package:buddy/screens/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState != null) {
      // user logged in
      return NavigationScreen();
    } else {
      return LoginOrRegisterScreen();
    }
  }
}
