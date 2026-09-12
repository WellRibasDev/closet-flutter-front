import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/wardrobe/presentation/wardrobe_detail_screen.dart';
import '../features/wardrobe/presentation/wardrobe_form_screen.dart';
import '../features/wardrobe/presentation/wardrobe_list_screen.dart';
import '../features/wishlist/presentation/wishlist_screen.dart';
import 'network/providers.dart';

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
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loggingIn = auth.isLoading;
      final loc = state.matchedLocation;

      if (loggingIn && loc != '/') return null;

      final isAuthed = auth.value?.isAuthenticated == true;
      final isPublic =
          loc == '/' || loc == '/login' || loc == '/register';

      if (!isAuthed && !isPublic) return '/login';
      if (isAuthed && (loc == '/login' || loc == '/register')) {
        return '/roupas';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/roupas',
        builder: (context, state) => const WardrobeListScreen(),
      ),
      GoRoute(
        path: '/roupas/nova',
        builder: (context, state) => const WardrobeFormScreen(),
      ),
      GoRoute(
        path: '/roupas/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WardrobeDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/roupas/:id/editar',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WardrobeFormScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/desejos',
        builder: (context, state) => const WishlistScreen(),
      ),
    ],
  );
});
