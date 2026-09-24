import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/categories.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_feedback.dart';
import '../data/models/wishlist_item.dart';
import 'wishlist_provider.dart';

class WishlistFormScreen extends ConsumerStatefulWidget {
  const WishlistFormScreen({super.key, this.itemId});

  final String? itemId;

  bool get isEditing => itemId != null;

  @override
  ConsumerState<WishlistFormScreen> createState() => _WishlistFormScreenState();
}

class _WishlistFormScreenState extends ConsumerState<WishlistFormScreen> {
  final _nomeCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  String _categoria = clothingCategories.first;
  int _prioridade = 1;
  String? _existingFotoUrl;
  File? _foto;
  var _saving = false;
  var _hydrated = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _marcaCtrl.dispose();
    _precoCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  void _hydrate(WishlistItem item) {
    if (_hydrated) return;
    _hydrated = true;
    _nomeCtrl.text = item.nome;
    _categoria = item.categoria ?? clothingCategories.first;
    _marcaCtrl.text = item.marca ?? '';
    _precoCtrl.text = item.precoAlvo?.toStringAsFixed(2) ?? '';
    _linkCtrl.text = item.linkRef ?? '';
    _prioridade = item.prioridade;
    _existingFotoUrl = item.fotoUrl;
  }

  InputDecoration _input(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.inkSoft),
      filled: true,
      fillColor: AppColors.blush.withValues(alpha: 0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.petal),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.petal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.pinkChip, width: 1.4),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _foto = File(file.path));
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.petal,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.roseDeep,
                ),
                title: Text(
                  'Galeria',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.roseDeep,
                ),
                title: Text(
                  'Câmera',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.length < 2) {
      AppToast.show(
        context,
        message: 'Informe um nome válido',
        icon: Icons.error_outline,
      );
      return;
    }

    final link = _linkCtrl.text.trim();
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        AppToast.show(
          context,
          message: 'Link inválido. Use http:// ou https://',
          icon: Icons.link_off,
        );
        return;
      }
    }

    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.'));
    final body = <String, dynamic>{
      'nome': nome,
      'categoria': _categoria,
      'prioridade': _prioridade,
      if (_marcaCtrl.text.trim().isNotEmpty) 'marca': _marcaCtrl.text.trim(),
      if (preco != null) 'precoAlvo': preco,
      if (link.isNotEmpty) 'linkRef': link,
    };

    setState(() => _saving = true);
    AppLoading.show(context, message: 'Salvando desejo...');

    try {
      final notifier = ref.read(wishlistProvider.notifier);
      if (widget.isEditing) {
        await notifier.updateItem(
          id: widget.itemId!,
          body: body,
          foto: _foto,
        );
      } else {
        await notifier.create(body: body, foto: _foto);
      }
      if (!mounted) return;
      AppToast.show(
        context,
        message: widget.isEditing ? 'Desejo atualizado' : 'Desejo adicionado ✨',
        icon: Icons.favorite,
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.message,
        icon: e.code == 'FOTO_UNAVAILABLE'
            ? Icons.warning_amber_rounded
            : Icons.error_outline,
      );
      if (e.code == 'FOTO_UNAVAILABLE') context.pop();
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Erro ao salvar desejo',
          icon: Icons.error_outline,
        );
      }
    } finally {
      AppLoading.hide();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (widget.isEditing) {
      final async = ref.watch(wishlistDetailProvider(widget.itemId!));
      body = async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.pinkChip),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e is ApiException ? e.message : 'Erro ao carregar desejo',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: AppColors.inkSoft),
            ),
          ),
        ),
        data: (item) {
          _hydrate(item);
          return _buildForm();
        },
      );
    } else {
      body = _buildForm();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.blush,
                      foregroundColor: AppColors.ink,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isEditing ? 'Editar desejo' : 'Novo desejo',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final hasFoto =
        _foto != null || (_existingFotoUrl != null && _existingFotoUrl!.isNotEmpty);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        TextField(
          controller: _nomeCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: _input('Nome *', icon: Icons.favorite_border),
        ),
        const SizedBox(height: 12),
        SoftSelectField<String>(
          label: 'Categoria',
          value: _categoria,
          items: clothingCategories,
          labelBuilder: (v) => v,
          onChanged: (v) => setState(() => _categoria = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _marcaCtrl,
          decoration: _input(
            'Marca',
            hint: "Ex: Levi's",
            icon: Icons.storefront_outlined,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _precoCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _input(
            'Preço alvo',
            hint: 'Ex: 199.90',
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _linkCtrl,
          keyboardType: TextInputType.url,
          decoration: _input(
            'Link da loja (opcional)',
            hint: 'https://...',
            icon: Icons.link,
          ),
        ),
        const SizedBox(height: 12),
        SoftSelectField<int>(
          label: 'Prioridade',
          value: _prioridade,
          items: const [0, 1, 2],
          labelBuilder: (v) => switch (v) {
                2 => 'Alta',
                1 => 'Média',
                _ => 'Baixa',
              },
          onChanged: (v) => setState(() => _prioridade = v),
        ),
        const SizedBox(height: 16),
        Text(
          'Foto (opcional)',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showPhotoOptions,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: hasFoto ? 200 : 110,
            decoration: BoxDecoration(
              color: AppColors.blush.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.petal),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasFoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _foto != null
                          ? Image.file(_foto!, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: _existingFotoUrl!,
                              fit: BoxFit.cover,
                            ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                                color: AppColors.roseDeep,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Trocar foto',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.roseDeep,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Tirar ou adicionar foto',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.pinkChip,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.isEditing ? 'Salvar alterações' : 'Salvar desejo',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }
}
