import 'package:closet_app/src/features/auth/data/auth_models.dart';
import 'package:closet_app/src/features/auth/presentation/auth_provider.dart';
import 'package:closet_app/src/features/wishlist/data/models/wishlist_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Espelha o contrato dos providers de dados: observar o token da sessão.
final _sessionWishlistProvider =
    AsyncNotifierProvider<_SessionWishlistNotifier, List<WishlistItem>>(
  _SessionWishlistNotifier.new,
);

class _SessionWishlistNotifier extends AsyncNotifier<List<WishlistItem>> {
  @override
  Future<List<WishlistItem>> build() async {
    final token = ref.watch(authProvider.select((s) => s.value?.token));
    if (token == null || token.isEmpty) {
      return const [];
    }
    final label = token.contains('elisa') ? 'elisa' : 'wellington';
    return [WishlistItem(id: '1', nome: 'desejo-$label')];
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthState();

  @override
  Future<void> login({required String email, required String senha}) async {
    state = AsyncData(
      AuthState(
        token: 'token-$email',
        user: User(id: email, email: email),
      ),
    );
  }

  @override
  Future<void> logout() async {
    state = const AsyncData(AuthState());
  }
}

void main() {
  test('dados de sessão são limpos e recarregados ao trocar de conta', () async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_FakeAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    // Garante que o build inicial do auth terminou antes do login.
    await container.read(authProvider.future);

    await container.read(authProvider.notifier).login(
          email: 'wellington@test.com',
          senha: 'x',
        );
    expect(
      (await container.read(_sessionWishlistProvider.future)).map((e) => e.nome),
      ['desejo-wellington'],
    );

    await container.read(authProvider.notifier).logout();
    expect(await container.read(_sessionWishlistProvider.future), isEmpty);

    await container.read(authProvider.notifier).login(
          email: 'elisa@test.com',
          senha: 'x',
        );
    expect(
      (await container.read(_sessionWishlistProvider.future)).map((e) => e.nome),
      ['desejo-elisa'],
    );
  });
}
