import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/motion/app_motion.dart';
import '../models/hangout.dart';
import '../models/photo_item.dart';
import '../services/hangout_repository.dart';
import '../widgets/creme_icons.dart';
import '../widgets/creme_pills.dart';
import '../widgets/resilient_image.dart';
import 'photo_scan_modal.dart';
import 'tap_to_share_modal.dart';

class HangoutDetailScreen extends StatefulWidget {
  final Hangout hangout;

  const HangoutDetailScreen({super.key, required this.hangout});

  @override
  State<HangoutDetailScreen> createState() => _HangoutDetailScreenState();
}

class _HangoutDetailScreenState extends State<HangoutDetailScreen> {
  void _openAddPhotoScan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhotoScanModal(hangoutId: widget.hangout.id),
    );
  }

  void _openTapToShare(Hangout hangout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TapToShareModal(hangout: hangout),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HangoutRepository.instance,
      builder: (context, _) {
        final currentHangout = HangoutRepository.instance.hangouts.firstWhere(
          (h) => h.id == widget.hangout.id,
          orElse: () => widget.hangout,
        );
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        final currentUser = HangoutRepository.instance.currentUser;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ---- Full-bleed hero -----------------------------------
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 430,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ResilientImage(
                            source: currentHangout.heroImageUrl,
                            fit: BoxFit.cover,
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: const Alignment(0, 0.05),
                                  colors: [
                                    AppColors.background.withValues(alpha: 0.98),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55],
                                ),
                              ),
                            ),
                          ),
                          // Back + actions row
                          Positioned(
                            top: MediaQuery.paddingOf(context).top + 8,
                            left: 16,
                            right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _TopDisc(
                                  child: const Icon(Icons.arrow_back,
                                      color: AppColors.textPrimary, size: 20),
                                  onTap: () => Navigator.pop(context),
                                ),
                                Row(
                                  children: [
                                    _TopDisc(
                                      child: const Icon(Icons.ios_share,
                                          color: AppColors.textPrimary,
                                          size: 20),
                                      onTap: () =>
                                          _openTapToShare(currentHangout),
                                    ),
                                    const SizedBox(width: 10),
                                    _TopDisc(
                                      child: AppIcons.heart(
                                          size: 20, color: AppColors.textPrimary),
                                      onTap: () {
                                        final photos =
                                            currentHangout.publicPhotos;
                                        if (photos.isNotEmpty) {
                                          HangoutRepository.instance
                                              .togglePhotoLike(
                                                  photos.first.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Title block over the hero's bottom fade
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentHangout.title.replaceAll('\n', ' '),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    height: 1.06,
                                    letterSpacing: -1.2,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () =>
                                      _openTapToShare(currentHangout),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ResilientAvatar(
                                        imageUrl:
                                            currentHangout.attendees.isNotEmpty
                                                ? currentHangout
                                                    .attendees.first.avatarUrl
                                                : '',
                                        radius: 10,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        hostName(currentHangout),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right,
                                          size: 18,
                                          color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- Action pills (the app's Cook/Plan/Remix/Ask row) -----
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 46,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          SoftPill(
                            'Post',
                            icon: Icons.local_fire_department_outlined,
                            filled: true,
                            onTap: currentUser == null
                                ? null
                                : _openAddPhotoScan,
                          ),
                          const SizedBox(width: 10),
                          SoftPill(
                            'Plan',
                            icon: Icons.add_chart_outlined,
                            onTap: () => _openTapToShare(currentHangout),
                          ),
                          const SizedBox(width: 10),
                          SoftPill(
                            'Remix',
                            icon: Icons.shuffle_on_outlined,
                            onTap: () =>                                            _openTapToShare(currentHangout),
                          ),
                          const SizedBox(width: 10),
                          SoftPill(
                            'Ask',
                            icon: Icons.auto_awesome_outlined,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- Description ------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text(
                        currentHangout.description.isEmpty
                            ? 'Photos from the share — add yours with the button below.'
                            : currentHangout.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // ---- Facts strip --------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Fact(
                              label: 'Photos',
                              value:
                                  '${currentHangout.publicPhotos.length}',
                            ),
                          ),
                          Expanded(
                            child: _Fact(
                              label: 'Share',
                              value: currentHangout.dateDescription,
                            ),
                          ),
                          Expanded(
                            child: _Fact(
                              label: 'Guests',
                              value:
                                  '${currentHangout.attendees.length}',
                            ),
                          ),
                          Expanded(
                            child: _Fact(
                              label: 'TTL',
                              value: currentHangout.ttlLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- Photo steps ---------------------------------------
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                    sliver: SliverList.builder(
                      itemCount: currentHangout.publicPhotos.length,
                      itemBuilder: (context, index) {
                        final photo =
                            currentHangout.publicPhotos[index];
                        return _PhotoStep(
                          photo: photo,
                          index: index,
                          onOpen: () =>                                _openTapToShare(currentHangout),
                        );
                      },
                    ),
                  ),

                  // ---- Guests row ------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 0, 0),
                      child: Text(
                        'Everyone in ${_firstName(currentHangout)}\'s share',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: currentHangout.attendees.length,
                        itemBuilder: (context, i) {
                          final a = currentHangout.attendees[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ResilientAvatar(
                                  imageUrl: a.avatarUrl,
                                  radius: 34,
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 76,
                                  child: Text(
                                    a.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 140),
                  ),
                ],
              ),

              // ---- Floating chip bar with photo counter ------------------
              Positioned(
                left: 0,
                right: 0,
                bottom: safeBottom + 10,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Step counter — white pill only after photos exist.
                      if (currentHangout.publicPhotos.isNotEmpty)
                        SoftPill(
                          '${currentHangout.publicPhotos.length}',
                          icon: Icons.camera_alt_outlined,
                          filled: true,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        )
                      else
                        const SizedBox.shrink(),
                      const SizedBox(width: 8),
                      SoftPill(
                        'Pass',
                        icon: Icons.qr_code_2,
                        onTap: () =>                                _openTapToShare(currentHangout),
                      ),
                      const SizedBox(width: 8),
                      SoftPill(
                        'Add',
                        icon: Icons.add,
                        onTap: _openAddPhotoScan,
                      ),
                      const SizedBox(width: 8),
                      SoftPill(
                        'Vault',
                        icon: Icons.inventory_2_outlined,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      SoftPill(
                        'Guests',
                        icon: Icons.group_outlined,
                        onTap: () =>                                _openTapToShare(currentHangout),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String hostName(Hangout h) {
    for (final a in h.attendees) {
      if (a.id == h.hostId) return a.name;
    }
    return h.attendees.isNotEmpty ? h.attendees.first.name : 'Open share';
  }

  String _firstName(Hangout h) {
    final name = hostName(h);
    return name.split(' ').first;
  }
}

class _TopDisc extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TopDisc({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      haptic: true,
      onTap: onTap,
      pressedScale: 0.9,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// A single photo rendered as a step: rounded image card with the
/// uploader chip and a warm tinted caption strip.
class _PhotoStep extends StatelessWidget {
  final PhotoItem photo;
  final int index;
  final VoidCallback onOpen;

  const _PhotoStep({
    required this.photo,
    required this.index,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PressableScale(
        haptic: true,
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.uploaderName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${photo.detectedAttendeeIds.length} tagged · ${photo.optimizedSizeFormatted}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: ResilientImage(
                    source: photo.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
