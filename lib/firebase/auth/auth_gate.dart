import 'package:buddy/providers/auth_provider.dart';
import 'package:buddy/screens/login_or_register_screen.dart';
import 'package:buddy/utils/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).value;

    if (authState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRoutes.home);
        }
      });

      return const SizedBox.shrink();
    }

    return const LoginOrRegisterScreen();
  }
}
