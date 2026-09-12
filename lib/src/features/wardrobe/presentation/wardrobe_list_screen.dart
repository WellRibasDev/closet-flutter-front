import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/categories.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/models/clothing_item.dart';
import 'wardrobe_provider.dart';

class WardrobeListScreen extends ConsumerStatefulWidget {
  const WardrobeListScreen({super.key});

  @override
  ConsumerState<WardrobeListScreen> createState() => _WardrobeListScreenState();
}

class _WardrobeListScreenState extends ConsumerState<WardrobeListScreen> {
  final _searchCtrl = TextEditingController();
  String? _categoria;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() async {
    await ref.read(wardrobeProvider.notifier).applyFilters(
          categoria: _categoria,
          busca: _searchCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncWardrobe = ref.watch(wardrobeProvider);

    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CLOSET DA ELISA',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'suas peças favoritas',
                            style: GoogleFonts.nunito(
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SoftIconButton(
                      tooltip: 'Wishlist',
                      icon: LucideIcons.heart,
                      onPressed: () => context.push('/desejos'),
                    ),
                    const SizedBox(width: 8),
                    SoftIconButton(
                      tooltip: 'Sair',
                      icon: LucideIcons.logOut,
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.08, end: 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar peça, cor, marca...',
                    prefixIcon: const Icon(LucideIcons.search),
                    suffixIcon: IconButton(
                      onPressed: _applyFilters,
                      icon: const Icon(LucideIcons.arrowRight),
                    ),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: 'Todas',
                        categoria: null,
                        selected: _categoria == null,
                        onPressed: () async {
                          setState(() => _categoria = null);
                          await ref.read(wardrobeProvider.notifier).applyFilters(
                                categoria: null,
                                busca: _searchCtrl.text.trim(),
                              );
                        },
                      ),
                    ),
                    ...clothingCategories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: c,
                          categoria: c,
                          selected: _categoria == c,
                          onPressed: () async {
                            setState(() => _categoria = c);
                            await ref
                                .read(wardrobeProvider.notifier)
                                .applyFilters(
                                  categoria: c,
                                  busca: _searchCtrl.text.trim(),
                                );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncWardrobe.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => SoftErrorView(
                    message: err is ApiException
                        ? err.message
                        : 'Erro ao carregar roupas',
                    onRetry: () =>
                        ref.read(wardrobeProvider.notifier).refresh(),
                  ),
                  data: (state) {
                    if (state.items.isEmpty) {
                      return RefreshIndicator(
                        color: AppColors.roseDeep,
                        onRefresh: () =>
                            ref.read(wardrobeProvider.notifier).refresh(),
                        child: ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyStateView(
                              icon: LucideIcons.shirt,
                              title: 'Closet vazio por enquanto',
                              subtitle:
                                  'Toque no + e adicione a primeira peça',
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.roseDeep,
                      onRefresh: () =>
                          ref.read(wardrobeProvider.notifier).refresh(),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 200) {
                            ref.read(wardrobeProvider.notifier).loadMore();
                          }
                          return false;
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.70,
                          ),
                          itemCount:
                              state.items.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final item = state.items[index];
                            return _ClothingCard(item: item, index: index);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/roupas/nova'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Nova peça'),
      )
          .animate()
          .fadeIn(delay: 200.ms)
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }
}

class _ClothingCard extends StatelessWidget {
  const _ClothingCard({required this.item, required this.index});

  final ClothingItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final catFill = AppColors.categoryFill(item.categoria, selected: true);
    final catInk = AppColors.categoryInk(item.categoria, selected: true);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/roupas/${item.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: 'roupa-foto-${item.id}',
                  child: item.fotoUrl != null && item.fotoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.fotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: catFill,
                            child: const Center(
                              child: CircularProgressIndicator(size: 22),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: catFill,
                            child: Icon(
                              LucideIcons.shirt,
                              size: 42,
                              color: catInk,
                            ),
                          ),
                        )
                      : Container(
                          color: catFill,
                          child: Icon(
                            LucideIcons.shirt,
                            size: 42,
                            color: catInk,
                          ),
                        ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 3,
                color: catFill,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: catFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        item.categoria,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: catInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (40 * index).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
