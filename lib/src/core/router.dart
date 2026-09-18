import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/style_guide_screen.dart';
import '../features/wardrobe/presentation/wardrobe_detail_screen.dart';
import '../features/wardrobe/presentation/wardrobe_form_screen.dart';
import '../features/wardrobe/presentation/wardrobe_list_screen.dart';
import '../features/wishlist/presentation/wishlist_detail_screen.dart';
import '../features/wishlist/presentation/wishlist_form_screen.dart';
import '../features/wishlist/presentation/wishlist_screen.dart';
import 'network/providers.dart';
import 'widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<int>(0);

  ref.listen(authProvider, (_, _) {
    authListenable.value++;
  });

  final apiClient = ref.read(apiClientProvider);
  apiClient.setUnauthorizedHandler(() async {
    await ref.read(authProvider.notifier).handleUnauthorized();
  });

  ref.onDispose(authListenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loggingIn = auth.isLoading;
      final loc = state.matchedLocation;

      if (loggingIn && loc != '/') return null;

      final isAuthed = auth.value?.isAuthenticated == true;
      final isPublic = loc == '/' || loc == '/login' || loc == '/register';

      if (!isAuthed && !isPublic) return '/login';
      if (isAuthed && (loc == '/login' || loc == '/register')) {
        return '/roupas';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/roupas',
                builder: (context, state) => const WardrobeListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/desejos',
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/perfil/editar',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/perfil/guia-estilo',
        builder: (context, state) => const StyleGuideScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/roupas/nova',
        builder: (context, state) => const WardrobeFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/roupas/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WardrobeDetailScreen(id: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/roupas/:id/editar',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WardrobeFormScreen(itemId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/desejos/nova',
        builder: (context, state) => const WishlistFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/desejos/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WishlistDetailScreen(id: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/desejos/:id/editar',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WishlistFormScreen(itemId: id);
        },
      ),
    ],
  );
});
