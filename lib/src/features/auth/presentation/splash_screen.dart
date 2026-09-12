import 'package:flutter/material.dart'
    hide
        Badge,
        ButtonStyle,
        Card,
        Chip,
        CircularProgressIndicator,
        ColorScheme,
        Theme,
        ThemeData;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/ui_kit.dart';
import '../data/auth_repository.dart';
import 'auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _error;
  var _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await repo.ensureHealthy();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = e is ApiException
            ? e.message
            : 'Não foi possível conectar à API. Verifique a internet e tente de novo.';
      });
      return;
    }

    await Future<void>.delayed(400.ms);
    await ref.read(authProvider.future);
    final auth = ref.read(authProvider).value;
    if (!mounted) return;

    if (auth?.isAuthenticated == true) {
      context.go('/roupas');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandMark(),
                  const SizedBox(height: 36),
                  if (_checking)
                    const CircularProgressIndicator(size: 28)
                        .animate(onPlay: (c) => c.repeat())
                        .fadeIn(),
                  if (_error != null) ...[
                    SoftErrorView(message: _error!, onRetry: _bootstrap),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
