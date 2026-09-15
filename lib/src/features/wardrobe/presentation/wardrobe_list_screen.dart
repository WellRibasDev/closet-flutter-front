import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/categories.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../wishlist/presentation/wishlist_provider.dart';
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

  String _greetingName() {
    final user = ref.read(authProvider).value?.user;
    final nome = user?.nome?.trim();
    if (nome != null && nome.isNotEmpty) {
      return nome.split(' ').first;
    }
    return 'Elisa';
  }

  String _todayLabel() {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    final now = DateTime.now();
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final asyncWardrobe = ref.watch(wardrobeProvider);
    final wishlistCount = ref.watch(wishlistProvider).value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.blush,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/roupas/nova'),
        backgroundColor: AppColors.pinkChip,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: asyncWardrobe.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    err is ApiException ? err.message : 'Erro ao carregar',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.read(wardrobeProvider.notifier).refresh(),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
          ),
          data: (state) {
            final items = state.items;
            final featured = items.isNotEmpty ? items.first : null;

            return RefreshIndicator(
              onRefresh: () => ref.read(wardrobeProvider.notifier).refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _todayLabel(),
                                      style: GoogleFonts.nunito(
                                        color: AppColors.inkSoft,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Olá, ${_greetingName()} 👋',
                                      style: GoogleFonts.nunito(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/perfil'),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.petal,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.roseDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchCtrl,
                            onSubmitted: (_) => _applyFilters(),
                            decoration: InputDecoration(
                              hintText: 'Buscar peças...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _Chip(
                                  label: 'Todos',
                                  selected: _categoria == null,
                                  onTap: () async {
                                    setState(() => _categoria = null);
                                    await _applyFilters();
                                  },
                                ),
                                ...clothingCategories.map(
                                  (c) => _Chip(
                                    label: c,
                                    selected: _categoria == c,
                                    onTap: () async {
                                      setState(() => _categoria = c);
                                      await _applyFilters();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (featured != null) ...[
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Text(
                                  'DESTAQUE DA SEMANA',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.roseDeep,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Ver todas >',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.roseDeep,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _FeaturedCard(
                              item: featured,
                              onTap: () => context.push('/roupas/${featured.id}'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _StatCard(
                                label: 'PEÇAS',
                                value: '${state.total}',
                                color: AppColors.apricot,
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                label: 'DESEJOS',
                                value: '$wishlistCount',
                                color: AppColors.lilac,
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                label: 'ITENS',
                                value: '${state.total + wishlistCount}',
                                color: AppColors.butter,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Text(
                                'TODAS AS PEÇAS (${state.total})',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.tune, size: 18, color: AppColors.inkSoft),
                              const SizedBox(width: 4),
                              Text(
                                'Filtrar',
                                style: GoogleFonts.nunito(
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 48, color: AppColors.inkSoft),
                          const SizedBox(height: 12),
                          Text(
                            'Sem resultados',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Tente outro filtro ou termo',
                            style: GoogleFonts.nunito(color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= items.length) {
                              ref.read(wardrobeProvider.notifier).loadMore();
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final item = items[index];
                            return _PieceCard(
                              item: item,
                              onTap: () => context.push('/roupas/${item.id}'),
                            );
                          },
                          childCount: items.length + (state.hasMore ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.pinkChip,
        backgroundColor: Colors.white,
        labelStyle: GoogleFonts.nunito(
          color: selected ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        side: BorderSide(
          color: selected ? AppColors.pinkChip : AppColors.chip,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.onTap});

  final ClothingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 88,
                  height: 110,
                  child: item.fotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.fotoUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.chip,
                          child: const Icon(Icons.checkroom),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.butter,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.categoria,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 16,
                          color: i < 4 ? const Color(0xFFE8B84A) : AppColors.chip,
                        ),
                      ),
                    ),
                    if (item.cor != null || item.marca != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        [item.marca, item.cor].whereType<String>().join(' · '),
                        style: GoogleFonts.nunito(
                          color: AppColors.inkSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({required this.item, required this.onTap});

  final ClothingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: item.fotoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.fotoUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.chip,
                              child: const Icon(Icons.checkroom, size: 40),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: const Icon(Icons.person, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    item.categoria,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
