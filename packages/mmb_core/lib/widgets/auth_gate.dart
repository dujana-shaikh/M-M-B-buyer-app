import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/enums.dart';
import '../models/app_user.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Decides what to show: login, waiting-for-approval, blocked, or the app.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.role, required this.loginScreen, required this.homeBuilder});
  final UserRole role;
  final Widget loginScreen;
  final Widget Function(AppUser user) homeBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (_, __) => const Scaffold(body: ErrorView()),
      data: (user) {
        if (user == null) return loginScreen;
        return ref.watch(currentUserProvider).when(
              loading: () => const Scaffold(body: LoadingView()),
              error: (_, __) => const Scaffold(body: ErrorView(message: 'Could not load your account.')),
              data: (profile) {
                if (profile == null) {
                  return const BlockedScreen(
                    icon: Icons.hourglass_top,
                    title: 'Setting up your account...',
                    message: 'This should only take a moment. If it does not finish, sign out and register again.',
                  );
                }
                if (profile.role != role) {
                  return BlockedScreen(
                    icon: Icons.block,
                    title: 'Wrong app for this account',
                    message: role == UserRole.seller
                        ? 'This account is not a distributor account. Please use the MMB Buyer app.'
                        : 'This account is a distributor account. Please use the MMB Seller app.',
                  );
                }
                switch (profile.status) {
                  case ApprovalStatus.approved:
                    return homeBuilder(profile);
                  case ApprovalStatus.pending:
                    return const BlockedScreen(
                      icon: Icons.verified_user_outlined,
                      title: 'Approval pending',
                      message: 'Your account is being reviewed by the MMB team. You will get access as soon as it is approved.',
                    );
                  default:
                    return const BlockedScreen(
                      icon: Icons.gpp_bad_outlined,
                      title: 'Account not active',
                      message: 'Your account is not active. Please contact MMB support.',
                    );
                }
              },
            );
      },
    );
  }
}

class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: icon,
            title: title,
            message: message,
            action: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: MmbColors.deepBlue),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ),
        ),
      );
}
