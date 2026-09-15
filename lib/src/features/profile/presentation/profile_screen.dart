import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../wardrobe/presentation/wardrobe_provider.dart';
import '../../wishlist/presentation/wishlist_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    final wardrobe = ref.watch(wardrobeProvider).value;
    final wishlist = ref.watch(wishlistProvider).value;

    final nome = auth?.user?.nome?.trim().isNotEmpty == true
        ? auth!.user!.nome!
        : 'Elisa';
    final email = auth?.user?.email ?? '—';
    final desde = auth?.user?.createdAt;
    final pecas = wardrobe?.total ?? 0;
    final desejos = wishlist?.length ?? 0;

    final byCat = <String, int>{};
    for (final item in wardrobe?.items ?? const []) {
      byCat[item.categoria] = (byCat[item.categoria] ?? 0) + 1;
    }
    final totalCat = byCat.values.fold<int>(0, (a, b) => a + b);
    final bars = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.blush,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8D4F5), Color(0xFFF8D0E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        child: const Icon(Icons.person, color: AppColors.roseDeep, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              email,
                              style: GoogleFonts.nunito(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                desde == null
                                    ? '⭐ Membro Closet da Elisa'
                                    : '⭐ Membro desde ${desde.month.toString().padLeft(2, '0')}/${desde.year}',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edição de perfil em breve')),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Editar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatMini(label: '$pecas Peças'),
                      const SizedBox(width: 8),
                      _StatMini(label: '$desejos Desejos'),
                      const SizedBox(width: 8),
                      _StatMini(label: '${pecas + desejos} Itens'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'GUIA DE ESTILO',
              style: GoogleFonts.nunito(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 12),
            if (bars.isEmpty)
              Text(
                'Adicione peças para ver a distribuição.',
                style: GoogleFonts.nunito(color: AppColors.inkSoft),
              )
            else
              ...bars.take(4).map((e) {
                final pct = totalCat == 0 ? 0.0 : e.value / totalCat;
                final color = AppColors.softTag(e.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          e.key,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: AppColors.chip,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(pct * 100).round()}%',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 18),
            _MenuTile(
              icon: Icons.notifications_none,
              color: const Color(0xFFE8B84A),
              title: 'Notificações',
              subtitle: 'Mantenha-se informado',
              onTap: () => _soon(context),
            ),
            _MenuTile(
              icon: Icons.palette_outlined,
              color: AppColors.pinkChip,
              title: 'Aparência',
              subtitle: 'Troque o tema e estilo',
              onTap: () => _soon(context),
            ),
            _MenuTile(
              icon: Icons.cloud_outlined,
              color: const Color(0xFF5B8DEF),
              title: 'Backup & Exportar',
              subtitle: 'Salve seus dados na nuvem',
              onTap: () => _soon(context),
            ),
            _MenuTile(
              icon: Icons.logout,
              color: AppColors.danger,
              title: 'Sair',
              subtitle: 'Encerrar sessão neste aparelho',
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Em breve')),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.18),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(color: AppColors.inkSoft, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkSoft),
    );
  }
}
