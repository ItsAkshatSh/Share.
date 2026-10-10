import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../services/google_auth_service.dart';
import '../widgets/creme_pills.dart';

import '../widgets/google_glyph.dart';
import '../widgets/resilient_image.dart';

/// styled sign-in: "Tell us about yourself".
///
/// Real Google OAuth first (mobile). Falls back to manual name/email entry
/// on web/desktop — that matches the reference's black profile form.
class GoogleLoginSheet extends StatefulWidget {
  const GoogleLoginSheet({super.key});

  @override
  State<GoogleLoginSheet> createState() => _GoogleLoginSheetState();
}

class _GoogleLoginSheetState extends State<GoogleLoginSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = GoogleAuthService.instance.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      if (user.subtitle.contains('@')) {
        _emailController.text = user.subtitle;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Real Google OAuth sign-in. On platforms where the plugin can't run the
  /// OAuth flow (web/desktop), the button is hidden and the manual form is
  /// used instead.
  Future<void> _googleSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await GoogleAuthService.instance.signIn();
      if (!mounted) return;
      if (user != null) {
        Navigator.pop(context);
        return;
      }
      // Real auth unavailable on this platform — reveal the manual form.
      setState(() => _busy = false);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Google sign-in failed: ${e.toString().split('\n').first}';
      });
    }
  }

  Future<void> _manualSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await GoogleAuthService.instance.signInWithProfile(
      name: _nameController.text,
      email: _emailController.text,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Enter your name and email to continue';
      });
      return;
    }
    Navigator.pop(context);
  }

  bool get _showGoogleButton => GoogleAuthService.instance.canSignInReal;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final user = GoogleAuthService.instance.currentUser;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, topInset > 40 ? 24 : 40, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Tell us about\nyourself',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.04,
                        letterSpacing: -1.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ResilientAvatar(
                    imageUrl: user?.avatarUrl ?? '',
                    radius: 34,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              if (_showGoogleButton && user == null) ...[
                _GoogleSigningButton(busy: _busy, onPressed: _googleSignIn),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),
                ),
              ],

              _LabeledField(
                label: 'Your name',
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
              ),
              _LabeledField(
                label: 'Choose a username',
                controller: _usernameProxy(_nameController),
                enabled: false,
              ),
              _LabeledField(
                label: 'Email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ],

              const SizedBox(height: 34),
              Align(
                alignment: Alignment.centerRight,
                child: RoundActionButton(
                  icon: Icons.arrow_forward,
                  onTap: _busy ? null : _manualSignIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The username field in the reference just mirrors a sensible default.
  TextEditingController _usernameProxy(TextEditingController source) =>
      _usernameFallback ??= _FallbackController(source);

  TextEditingController? _usernameFallback;
}

/// Follows the name field to suggest a username (lowercased, joined).
class _FallbackController extends TextEditingController {
  final TextEditingController source;

  _FallbackController(this.source) {
    text = _suggest(source.text);
    source.addListener(_sync);
  }

  void _sync() {
    text = _suggest(source.text);
  }

  static String _suggest(String name) {
    final cleaned = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return cleaned.isEmpty ? '' : cleaned;
  }
}

/// field: nothing but a small gray label above a large white value,
/// separated from the next field by a hairline.
class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}

/// The official Google-branded sign-in button (white pill, four-colour G,
/// "Continue with Google" in Google Sans tone).
class _GoogleSigningButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;

  const _GoogleSigningButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: PressableScale(
        haptic: true,
        onTap: busy ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                const GoogleGlyph(size: 20),
              const SizedBox(width: 12),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16141C),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
