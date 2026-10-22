import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/services/push_notification_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/profile_settings/data/settings_repository.dart';
import 'router.dart';

class ZeroApp extends ConsumerStatefulWidget {
  const ZeroApp({super.key});

  @override
  ConsumerState<ZeroApp> createState() => _ZeroAppState();
}

class _ZeroAppState extends ConsumerState<ZeroApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    // Automatically manage push notification registration on login / logout
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if ((previous == null || !previous.isAuthenticated) && next.isAuthenticated) {
        ref.read(pushNotificationServiceProvider).registerCurrentToken();
      } else if (previous != null && previous.isAuthenticated && !next.isAuthenticated) {
        ref.read(pushNotificationServiceProvider).unregisterOnLogout();
      }
    });

    // Global session expiration handler (401 unauthenticated redirect)
    ref.listen<AsyncValue<void>>(authExpirationEventProvider, (_, next) {
      if (next.hasValue) {
        ref.read(authControllerProvider.notifier).logout();
        router.go('/login');
      }
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
