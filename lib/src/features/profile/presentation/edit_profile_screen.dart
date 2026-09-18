import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../auth/presentation/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaAtualCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();

  String? _existingFotoUrl;
  File? _foto;
  var _loading = false;
  var _hydrated = false;
  String? _error;
  var _changePassword = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromAuth() {
    if (_hydrated) return;
    final user = ref.read(authProvider).value?.user;
    if (user == null) return;
    _hydrated = true;
    _nomeCtrl.text = user.nome ?? '';
    _emailCtrl.text = user.email;
    _existingFotoUrl = user.fotoUrl;
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeCtrl.text.trim();
    String? senhaAtual;
    String? novaSenha;

    if (_changePassword) {
      senhaAtual = _senhaAtualCtrl.text;
      novaSenha = _novaSenhaCtrl.text;
      if (novaSenha != _confirmaSenhaCtrl.text) {
        setState(() => _error = 'A confirmação da senha não confere');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    AppLoading.show(context, message: 'Salvando perfil...');

    try {
      await ref.read(authProvider.notifier).updateProfile(
            nome: nome,
            senhaAtual: senhaAtual,
            novaSenha: novaSenha,
            foto: _foto,
          );
      if (mounted) {
        AppToast.show(
          context,
          message: 'Perfil atualizado',
          icon: Icons.check_circle_outline,
        );
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao salvar perfil');
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

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    _hydrateFromAuth();

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
                      'Editar perfil',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
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
                    Center(
                      child: GestureDetector(
                        onTap: _showPickerSheet,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.white,
                              backgroundImage: _foto != null
                                  ? FileImage(_foto!)
                                  : (_existingFotoUrl != null &&
                                          _existingFotoUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          _existingFotoUrl!,
                                        )
                                      : null),
                              child: hasFoto
                                  ? null
                                  : const Icon(
                                      Icons.person,
                                      size: 52,
                                      color: AppColors.roseDeep,
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.pinkChip,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Toque para tirar ou escolher foto',
                        style: GoogleFonts.nunito(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: _input('Nome', icon: Icons.badge_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      enabled: false,
                      decoration: _input(
                        'E-mail',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O e-mail não pode ser alterado por aqui.',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Alterar senha',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                      ),
                      value: _changePassword,
                      activeColor: AppColors.pinkChip,
                      onChanged: (v) => setState(() => _changePassword = v),
                    ),
                    if (_changePassword) ...[
                      TextFormField(
                        controller: _senhaAtualCtrl,
                        obscureText: true,
                        decoration: _input(
                          'Senha atual',
                          icon: Icons.lock_outline,
                        ),
                        validator: (v) {
                          if (!_changePassword) return null;
                          if (v == null || v.isEmpty) {
                            return 'Informe a senha atual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _novaSenhaCtrl,
                        obscureText: true,
                        decoration: _input(
                          'Nova senha',
                          icon: Icons.lock_reset,
                        ),
                        validator: (v) {
                          if (!_changePassword) return null;
                          if (v == null || v.length < 6) {
                            return 'Mínimo de 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmaSenhaCtrl,
                        obscureText: true,
                        decoration: _input(
                          'Confirmar nova senha',
                          icon: Icons.lock_outline,
                        ),
                        validator: (v) {
                          if (!_changePassword) return null;
                          if (v != _novaSenhaCtrl.text) {
                            return 'As senhas não conferem';
                          }
                          return null;
                        },
                      ),
                    ],
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
                              'Salvar perfil',
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
