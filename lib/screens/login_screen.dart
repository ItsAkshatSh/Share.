import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../services/google_auth_service.dart';
import '../widgets/google_glyph.dart';
import 'google_login_sheet.dart';
import 'home_screen.dart';

/// Full-screen sign-in, styled after the Creme reference: full-bleed photos
/// of people-in-the-moment as a crossfading slideshow, darkened with a scrim,
/// the wordmark up top and stacked auth buttons pinned to the bottom.
///
/// This is the app's home while the user is signed out. Successful sign-in
/// (Google, or the manual profile sheet for email) hands over to the usual
/// feed flow.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// Curated shots — friends at dinners, parties, nights out: the moments
  /// this app exists to share. Bundled as assets so the background is
  /// always there, no network required.
  static const List<String> _slides = [
    'assets/images/login/slide_1.jpg',
    'assets/images/login/slide_2.jpg',
    'assets/images/login/slide_3.jpg',
    'assets/images/login/slide_4.jpg',
    'assets/images/login/slide_5.jpg',
  ];

  /// Long enough to take each shot in, short enough that the page feels alive.
  static const Duration _slideDuration = Duration(seconds: 5);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _slide = 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scheduleNextSlide();
  }

  void _scheduleNextSlide() {
    Future.delayed(LoginScreen._slideDuration, () {
      if (!mounted) return;
      setState(() {
        _slide = (_slide + 1) % LoginScreen._slides.length;
      });
      _scheduleNextSlide();
    });
  }

  /// Hand over to the feed once someone is signed in (onboarding removed).
  Future<void> _enterApp() async {
    const next = HomeScreen();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.slow,
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  Future<void> _googleSignIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await GoogleAuthService.instance.signIn();
      if (!mounted) return;
      if (user != null) {
        await _enterApp();
        return;
      }
      // Real OAuth unavailable or canceled — cancel is silent; anything
      // else falls back to the manual profile sheet the email button opens.
      final reason = GoogleAuthService.instance.lastError;
      setState(() {
        _busy = false;
        _error = reason;
      });
      if (!GoogleAuthService.instance.canSignInReal) {
        await _emailSignIn();
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().split('\n').first;
      });
    }
  }

  Future<void> _emailSignIn() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GoogleLoginSheet(),
    );
    if (!mounted) return;
    // The sheet pops itself when a profile is saved.
    if (GoogleAuthService.instance.isSignedIn) {
      await _enterApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Rich fallback surface — the page must never read as plain black,
          // even while photos are loading or unavailable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4630F0),
                  Color(0xFF1C00CB),
                  Color(0xFF12009A),
                  Color(0xFF06001F),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          _BackgroundSlideshow(index: _slide, sources: LoginScreen._slides),
          // Bottom-progressive scrim — buttons stay readable over any shot.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.38, 0.62, 1.0],
                colors: [
                  Color(0x59000000),
                  Color(0x0D000000),
                  Color(0x73000000),
                  Color(0xD1000000),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 26),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: _Wordmark(),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null) ...[
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _AuthButton(
                        label: 'Continue with Google',
                        filled: true,
                        onTap: _busy ? null : _googleSignIn,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : const GoogleGlyph(size: 20),
                      ),
                      const SizedBox(height: 12),
                      _AuthButton(
                        label: 'Continue with email',
                        filled: false,
                        onTap: _busy ? null : _emailSignIn,
                        child: const Icon(
                          Icons.alternate_email,
                          size: 21,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white.withValues(alpha: 0.72),
                          ),
                          children: [
                            const TextSpan(
                                text: 'By continuing you agree to our\n'),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            const TextSpan(text: '  and  '),
                            TextSpan(
                              text: 'Terms of use',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background slideshow
// ---------------------------------------------------------------------------

/// Crossfading full-bleed photos. Each shot gets a very slow push-in (Ken
/// Burns breathing) so the page never feels frozen between crossfades.
class _BackgroundSlideshow extends StatelessWidget {
  final int index;
  final List<String> sources;

  const _BackgroundSlideshow({
    required this.index,
    required this.sources,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        for (int i = 0; i < sources.length; i++)
          AnimatedOpacity(
            opacity: i == index ? 1 : 0,
            duration:
                reduce ? Duration.zero : const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            child: _KenBurnsImage(source: sources[i]),
          ),
      ],
    );
  }
}

/// A very slow, subtle push-in on the full-bleed photo.
class _KenBurnsImage extends StatefulWidget {
  final String source;

  const _KenBurnsImage({required this.source});

  @override
  State<_KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<_KenBurnsImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = reduce ? 0.0 : _controller.value;
        return Transform.scale(
          scale: 1.0 + 0.06 * t,
          child: child,
        );
      },
      child: Image.asset(
        widget.source,
        fit: BoxFit.cover,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wordmark
// ---------------------------------------------------------------------------

/// Stacked, chunky white wordmark echoing the reference's rounded logo —
/// "Share." split over two lines with a slight playful tilt.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.rotate(
          angle: -0.04,
          child: const Text(
            'Sha',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              height: 0.95,
              color: AppColors.white,
            ),
          ),
        ),
        Transform.rotate(
          angle: 0.03,
          child: const Text(
            're.',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              height: 0.95,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Auth buttons
// ---------------------------------------------------------------------------

/// One stacked auth row. [filled] gives the solid-white Google treatment;
/// otherwise it's the translucent dark pill from the reference.
class _AuthButton extends StatelessWidget {
  final String label;
  final Widget child;
  final bool filled;
  final VoidCallback? onTap;

  const _AuthButton({
    required this.label,
    required this.child,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      haptic: true,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color:
              filled ? AppColors.white : AppColors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: filled ? AppColors.textPrimary : AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
