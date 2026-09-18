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
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String _categoria = clothingCategories.first;
  int _prioridade = 1;
  String? _existingFotoUrl;
  File? _foto;
  var _loading = false;
  var _hydrated = false;
  String? _error;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _marcaCtrl.dispose();
    _precoCtrl.dispose();
    _linkCtrl.dispose();
    _obsCtrl.dispose();
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
    _obsCtrl.text = item.observacao ?? '';
    _prioridade = item.prioridade;
    _existingFotoUrl = item.fotoUrl;
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _foto = File(file.path));
  }

  Future<void> _showPickerSheet() async {
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
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.roseDeep),
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
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.roseDeep),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final link = _linkCtrl.text.trim();
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        setState(() => _error = 'Link inválido. Use http:// ou https://');
        return;
      }
    }

    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.'));

    setState(() {
      _loading = true;
      _error = null;
    });
    AppLoading.show(
      context,
      message: widget.isEditing ? 'Salvando desejo...' : 'Adicionando desejo...',
    );

    final body = <String, dynamic>{
      'nome': _nomeCtrl.text.trim(),
      'categoria': _categoria,
      'prioridade': _prioridade,
      if (_marcaCtrl.text.trim().isNotEmpty) 'marca': _marcaCtrl.text.trim(),
      if (_obsCtrl.text.trim().isNotEmpty) 'observacao': _obsCtrl.text.trim(),
      if (preco != null) 'precoAlvo': preco,
      if (link.isNotEmpty) 'linkRef': link,
    };

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
      if (mounted) {
        AppToast.show(
          context,
          message: widget.isEditing ? 'Desejo atualizado' : 'Desejo adicionado ✨',
          icon: Icons.favorite,
        );
        context.go('/desejos');
      }
    } on ApiException catch (e) {
      if (e.code == 'FOTO_UNAVAILABLE' && mounted) {
        AppToast.show(
          context,
          message: e.message,
          icon: Icons.warning_amber_rounded,
        );
        context.go('/desejos');
        return;
      }
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao salvar desejo');
    } finally {
      AppLoading.hide();
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _input(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.inkSoft),
      filled: true,
      fillColor: AppColors.blush.withValues(alpha: 0.45),
      labelStyle: GoogleFonts.nunito(color: AppColors.inkSoft),
      hintStyle: GoogleFonts.nunito(color: AppColors.inkSoft),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final asyncItem = ref.watch(wishlistDetailProvider(widget.itemId!));
      return asyncItem.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.blush,
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: AppColors.blush,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new),
            ),
          ),
          body: Center(
            child: Text(err is ApiException ? err.message : 'Erro ao carregar'),
          ),
        ),
        data: (item) {
          _hydrate(item);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final hasFoto =
        _foto != null || (_existingFotoUrl != null && _existingFotoUrl!.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.blush,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
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
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: _input('Nome *', icon: Icons.favorite_border),
                      validator: (v) {
                        if (v == null || v.trim().length < 2) {
                          return 'Nome com no mínimo 2 caracteres';
                        }
                        return null;
                      },
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
                    TextFormField(
                      controller: _marcaCtrl,
                      decoration: _input(
                        'Marca',
                        hint: "Ex: Levi's",
                        icon: Icons.storefront_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _precoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _input(
                        'Preço alvo',
                        hint: 'Ex: 199.90',
                        icon: Icons.attach_money,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _obsCtrl,
                      maxLines: 3,
                      decoration: _input(
                        'Observação',
                        hint: 'Onde viu, ocasião…',
                      ).copyWith(alignLabelWithHint: true),
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
                      onTap: _showPickerSheet,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.petal),
                        ),
                        child: hasFoto
                            ? Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(15),
                                    ),
                                    child: SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: _foto != null
                                          ? Image.file(_foto!, fit: BoxFit.cover)
                                          : CachedNetworkImage(
                                              imageUrl: _existingFotoUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Foto selecionada',
                                            style: GoogleFonts.nunito(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Toque para trocar',
                                            style: GoogleFonts.nunito(
                                              color: AppColors.inkSoft,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 14),
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: AppColors.roseDeep,
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
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.nunito(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pinkChip,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Salvar alterações'
                                  : 'Salvar desejo',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
