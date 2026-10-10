import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../models/hangout.dart';
import '../services/google_auth_service.dart';
import '../services/hangout_repository.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/creme_photo_tile.dart';
import '../widgets/creme_top_bar.dart';
import '../widgets/resilient_image.dart';
import 'consent_vault_modal.dart';
import 'create_share_sheet.dart';
import 'world_screen.dart';
import 'google_login_sheet.dart';
import 'hangout_detail_screen.dart';
import 'photo_scan_modal.dart';
import 'saved_album_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'storage_dashboard_modal.dart';

/// Home, restyled to the dark "Next steps" reference: a Post card, an
/// accent "What's next?" input (type a plan and it becomes a share), and
/// a "More from ..." photo strip. The light-paper top bar and the
/// floating dock carry over from the previous design.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _planController = TextEditingController();
  bool _showWorld = false;

  static const _page = Color(0xFF0B0A0E);
  static const _card = Color(0xFF1A181F);
  static const _hairline = Color(0x1AFFFFFF);

  // Canned ideas that prefill the plan input — right-aligned like chat
  // bubbles, per the reference.
  static const List<String> _ideas = [
    'Beach day this Saturday?',
    'Dinner party on Friday?',
    'Museum run next weekend?',
  ];

  @override
  void dispose() {
    _planController.dispose();
    super.dispose();
  }

  void _openGoogleLogin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoogleLoginSheet(),
    );
  }

  void _sheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  /// Avatar tap — profile switcher (kept for the top bar avatar).
  Future<void> _openAvatarMenu() async {
    final auth = GoogleAuthService.instance;
    final user = auth.currentUser;
    if (user == null) {
      _openGoogleLogin();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  ResilientAvatarLite(
                      imageUrl: user.avatarUrl, radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          user.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined,
                  color: AppColors.textPrimary),
              title: const Text('Settings',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _openSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.textPrimary),
              title: const Text('Sign out',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                await auth.signOut();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  void _openSaved() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedAlbumScreen()),
    );
  }

  void _openConsentVault() => _sheet(const ConsentVaultModal());
  void _openStorageDashboard() => _sheet(const StorageDashboardModal());

  void _navigateToDetail(Hangout hangout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HangoutDetailScreen(hangout: hangout),
      ),
    );
  }

  void _openCreateShare() {
    if (!GoogleAuthService.instance.isSignedIn) {
      _openGoogleLogin();
      return;
    }
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateShareSheet(),
    );
  }

  void _openPhotoScanner(String hangoutId) {
    if (!GoogleAuthService.instance.isSignedIn) {
      _openGoogleLogin();
      return;
    }
    _sheet(PhotoScanModal(hangoutId: hangoutId));
  }

  void _onNavItemSelected(NavItem item) {
    switch (item) {
      case NavItem.home:
        setState(() => _showWorld = false);
      case NavItem.world:
        // The globe — "your world" face of home.
        setState(() => _showWorld = true);
      case NavItem.saved:
        _openSaved();
      case NavItem.settings:
        _openStorageDashboard();
    }
  }

  /// Post — drop photos into the current share (or start one first).
  void _post() {
    if (!GoogleAuthService.instance.isSignedIn) {
      _openGoogleLogin();
      return;
    }
    final h = HangoutRepository.instance.selectedHangoutOrNull;
    if (h == null) {
      _openCreateShare();
    } else {
      _openPhotoScanner(h.id);
    }
  }

  /// Type a plan into the box → it becomes a share everyone can drop
  /// photos into. That's the whole product loop, no jargon needed.
  void _planFromText(String raw) {
    if (!GoogleAuthService.instance.isSignedIn) {
      _openGoogleLogin();
      return;
    }
    final text = raw.trim();
    if (text.isEmpty) return;

    final hangout = HangoutRepository.instance.createShare(
      title: text,
      category: 'Hangout',
    );
    _planController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    _navigateToDetail(hangout);
  }

  /// Fill the plan box with a starter idea and put the cursor in it.
  void _prefillPlanBox() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _planController.text = _ideas.first);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        HangoutRepository.instance,
        GoogleAuthService.instance,
      ]),
      builder: (context, _) {
        final repo = HangoutRepository.instance;
        final user = repo.currentUser;
        final selectedHangout = repo.selectedHangoutOrNull;
        final pendingConsentCount = repo.pendingConsentPhotos.length;
        final signedIn = user != null;

        if (_showWorld) {
          return WorldScreen(
            onNavItemSelected: _onNavItemSelected,
            onVaultTap: _openConsentVault,
            onAddTap: _post,
            pendingVaultCount: pendingConsentCount,
            onSeeAll: () {},
          );
        }

        return Scaffold(
          backgroundColor: _page,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: HomeTopBar(
                      signedIn: signedIn,
                      inkColor: AppColors.white,
                      onBell: signedIn ? _openConsentVault : null,
                      onSearch: _openSearch,
                      onSignIn: signedIn ? null : _openGoogleLogin,
                      onAvatar: signedIn ? () => _openAvatarMenu() : null,
                    ),
                  ),

                  if (!signedIn)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _SignedOutEmpty(onSignIn: _openGoogleLogin),
                    )
                  else if (selectedHangout == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NoSharesEmpty(onPrefill: _prefillPlanBox),
                    )
                  else ...[
                    const SliverToBoxAdapter(
                      child: _SectionHeader(title: 'Next steps'),
                    ),

                    // ---- Post card -------------------------------------
                    SliverToBoxAdapter(
                      child: _PostCard(
                        thumbnailUrl: _postThumbUrl(repo),
                        onPost: _post,
                      ),
                    ),

                    // ---- Plan input card --------------------------------
                    SliverToBoxAdapter(
                      child: _PlanCard(
                        controller: _planController,
                        avatarUrl: user.avatarUrl,
                        ideas: _ideas,
                        onIdeaTap: (idea) {
                          setState(() => _planController.text = idea);
                        },
                        onSubmit: _planFromText,
                      ),
                    ),

                    // ---- hairline ---------------------------------------
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(color: _hairline, height: 84),
                      ),
                    ),

                    // ---- More from <share> -----------------------------
                    SliverToBoxAdapter(
                      child: _MoreSection(
                        hangout: selectedHangout,
                        repo: repo,
                        onOpenDetail: () => _navigateToDetail(selectedHangout),
                        onOpenPhoto: _navigateToDetail,
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 150)),
                  ],
                ],
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AppNavBar(
                  current: NavItem.home,
                  onChanged: _onNavItemSelected,
                  badgeCount: pendingConsentCount,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The scribble-framed photo inside the Post card — most recent photo
  /// anywhere, else the selected share's hero.
  static String _postThumbUrl(HangoutRepository repo) {
    for (final h in repo.hangouts) {
      for (final p in h.photos) {
        if (p.imageUrl.isNotEmpty) return p.imageUrl;
      }
    }
    final hero = repo.selectedHangoutOrNull?.heroImageUrl ?? '';
    return hero;
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AppColors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Post card
// ---------------------------------------------------------------------------

class _PostCard extends StatelessWidget {
  final String thumbnailUrl;
  final VoidCallback onPost;

  const _PostCard({
    required this.thumbnailUrl,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    final hasThumb = thumbnailUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(22, 20, 20, 22),
      decoration: BoxDecoration(
        color: _HomeScreenState._card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Got hangout photos?',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'They drop straight into your share.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0x99FFFFFF),
                  ),
                ),
                const SizedBox(height: 16),
                PressableScale(
                  haptic: true,
                  onTap: onPost,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_rounded,
                            size: 18, color: AppColors.textPrimary),
                        SizedBox(width: 8),
                        Text(
                          'Post',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Scribble-style framed snapshot of the latest photo.
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 86,
              height: 92,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.85),
                  width: 2.4,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasThumb
                    ? ResilientImageLite(
                        source: thumbnailUrl,
                        fit: BoxFit.cover,
                      )
                    : const ColoredBox(
                        color: Color(0xFF2A2830),
                        child: Icon(
                          Icons.image_outlined,
                          color: Color(0x55FFFFFF),
                          size: 26,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan card ("What's next?") — accent gradient, idea chips, input + avatar.
// Typing a plan and sending turns it into a share.
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  final TextEditingController controller;
  final String avatarUrl;
  final List<String> ideas;
  final ValueChanged<String> onIdeaTap;
  final ValueChanged<String> onSubmit;

  const _PlanCard({
    required this.controller,
    required this.avatarUrl,
    required this.ideas,
    required this.onIdeaTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4630F0),
            Color(0xFF1C00CB),
            Color(0xFF12009A),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: AppColors.white),
              SizedBox(width: 8),
              Text(
                "What's next?",
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Idea chips, right-aligned like the reference's chat bubbles.
          for (final idea in ideas) ...[
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => onIdeaTap(idea),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    idea,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: onSubmit,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                  cursorColor: AppColors.white,
                  decoration: InputDecoration(
                    hintText: 'Where to next?',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white.withValues(alpha: 0.62),
                    ),
                    filled: true,
                    fillColor: AppColors.white.withValues(alpha: 0.14),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ResilientAvatarLite(imageUrl: avatarUrl, radius: 22),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "More from <share>" strip
// ---------------------------------------------------------------------------

class _MoreSection extends StatelessWidget {
  final Hangout hangout;
  final HangoutRepository repo;
  final VoidCallback onOpenDetail;
  final ValueChanged<Hangout> onOpenPhoto;

  const _MoreSection({
    required this.hangout,
    required this.repo,
    required this.onOpenDetail,
    required this.onOpenPhoto,
  });

  @override
  Widget build(BuildContext context) {
    // Photos of the current share first; fill out with other shares'
    // hero shots so the strip is never empty.
    final List<(Hangout, String)> shots = [
      for (final p in hangout.photos)
        if (p.imageUrl.isNotEmpty) (hangout, p.imageUrl),
      for (final h in repo.hangouts)
        if (h.id != hangout.id && h.heroImageUrl.isNotEmpty)
          (h, h.heroImageUrl),
    ];

    final hasOwn = hangout.photos.any((p) => p.imageUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 8, 14),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenDetail,
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: hasOwn ? 'More from ' : 'New shares  ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                        children: [
                          if (hasOwn)
                            TextSpan(
                              text: hangout.title.replaceAll('\n', ' '),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white.withValues(alpha: 0.45),
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 26, color: Color(0x88FFFFFF)),
                ],
              ),
            ),
          ),
          if (shots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'post something and it lands right here.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.white.withValues(alpha: 0.55),
                ),
              ),
            )
          else
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: shots.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final (h, url) = shots[i];
                  return PhotoTile(
                    imageUrl: url,
                    aspect: 0.82,
                    onTap: () => onOpenPhoto(h),
                  );
                },
              ),
            ),
        ],
      );
  }
}

// ---------------------------------------------------------------------------
// Empty states (dark variants of the old ones)
// ---------------------------------------------------------------------------

class _SignedOutEmpty extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignedOutEmpty({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome,
              size: 56, color: AppColors.white.withValues(alpha: 0.85)),
          const SizedBox(height: 26),
          const Text(
            'hey friend',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "this is where your photos live.\nsign in to post your first memory.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: 30),
          _BrightCta(label: 'get started', onTap: onSignIn),
        ],
      ),
    );
  }
}

class _NoSharesEmpty extends StatelessWidget {
  /// Where this empty state differs from a plain prompt: it prefills the
  /// plan box above so "type a plan → get a share" is discoverable too.
  final VoidCallback onPrefill;

  const _NoSharesEmpty({required this.onPrefill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration_outlined,
              size: 52, color: AppColors.white.withValues(alpha: 0.85)),
          const SizedBox(height: 22),
          const Text(
            'no shares yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "type what you're dreaming up in the box above,\nor start one for your next hangout.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: 28),
          _BrightCta(
            label: 'start a share',
            onTap: onPrefill,
          ),
        ],
      ),
    );
  }
}

/// Full-width CTA — indigo, as in the current design; it reads well over
/// the dark page so it carries over unchanged.
class _BrightCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BrightCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      haptic: true,
      pressedScale: 0.98,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.onAccent,
          ),
        ),
      ),
    );
  }
}
