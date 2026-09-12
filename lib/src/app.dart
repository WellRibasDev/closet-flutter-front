import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'core/router.dart';
import 'core/theme/app_theme.dart';

class ClosetApp extends ConsumerWidget {
  const ClosetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Closet da Elisa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.material,
      builder: (context, child) {
        return shadcn.Theme(
          data: AppTheme.shadcnTheme,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
