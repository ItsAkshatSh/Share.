import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../models/hangout.dart';
import '../services/hangout_repository.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/creme_top_bar.dart';
import 'consent_vault_modal.dart';
import 'hangout_detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// Home tab 1 — the world. A real textured Earth (flutter_earth_globe) with an
/// album point pinned at every share's coordinates. Tap a point to open the album.
class WorldScreen extends StatefulWidget {
  final ValueChanged<NavItem> onNavItemSelected;
  final VoidCallback onVaultTap;
  final VoidCallback onAddTap;
  final int pendingVaultCount;
  final VoidCallback onSeeAll;

  const WorldScreen({
    super.key,
    required this.onNavItemSelected,
    required this.onVaultTap,
    required this.onAddTap,
    required this.pendingVaultCount,
    required this.onSeeAll,
  });

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  late final FlutterEarthGlobeController _controller =
      FlutterEarthGlobeController(
    rotationSpeed: 0.05,
    isBackgroundFollowingSphereRotation: true,
    surface: Image.asset('assets/globe/earth-day.jpg').image,
    showAtmosphere: true,
    atmosphereColor: const Color(0xFF5D8BFF),
    atmosphereOpacity: 0.32,
    atmosphereThickness: 0.06,
  );

  Hangout? _selected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetail(Hangout h) {
    HangoutRepository.instance.selectHangout(h.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HangoutDetailScreen(hangout: h)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HangoutRepository.instance,
      builder: (context, _) {
        final repo = HangoutRepository.instance;
        final shares = [
          for (final h in repo.hangouts)
            if (h.latitude != null && h.longitude != null) h,
        ];

        // Keep controller points in sync with shares.
        _controller.points
            .removeWhere((p) => !shares.any((h) => h.id == p.id));
        for (final h in shares) {
          _controller.addPoint(
            Point(
              id: h.id,
              coordinates: GlobeCoordinates(h.latitude!, h.longitude!),
              label: h.title.replaceAll('\n', ' '),
              isLabelVisible: true,
              style: PointStyle(
                color: h.accentColor,
                size: _selected?.id == h.id ? 13 : 9,
                altitude: 0.02,
              ),
              onTap: () => setState(() => _selected = h),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    HomeTopBar(
                      signedIn: repo.currentUser != null,
                      inkColor: AppColors.textPrimary,
                      onBell: _openVault,
                      onSearch: _openSearch,
                      onAvatar: _openSettings,
                    ),
                    const SizedBox(height: 6),
                    const _Eyebrow('YOUR WORLD'),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          FlutterEarthGlobe(
                            controller: _controller,
                            radius: 148,
                          ),
                        ],
                      ),
                    ),
                    // Selected-share card, in the reference's voice.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: _selected == null
                          ? const Text(
                              'tap a point to open its album',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                                letterSpacing: 0.3,
                              ),
                            )
                          : _SelectedCard(
                              key: ValueKey(_selected!.id),
                              hangout: _selected!,
                              onOpen: () => _openDetail(_selected!),
                              onDismiss: () =>
                                  setState(() => _selected = null),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AppNavBar(
                  current: NavItem.world,
                  onChanged: widget.onNavItemSelected,
                  badgeCount: widget.pendingVaultCount,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openVault() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ConsentVaultModal(),
      );

  void _openSearch() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      );

  void _openSettings() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.4,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  final Hangout hangout;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  const _SelectedCard({
    super.key,
    required this.hangout,
    required this.onOpen,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadow(blur: 22, y: 8, alpha: 0.12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hangout.accentColor,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hangout.title.replaceAll('\n', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${hangout.publicPhotos.length} photos · ${hangout.ttlLabel}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textMuted),
          ),
          Semantics(
            button: true,
            child: PressableScale(
              haptic: true,
              onTap: onOpen,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'open',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onAccent,
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
