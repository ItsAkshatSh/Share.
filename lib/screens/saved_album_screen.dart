import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/photo_item.dart';
import '../services/hangout_repository.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/panel.dart';
import '../widgets/resilient_image.dart';

/// Every photo the user liked or saved to their device, gathered from all
/// shares into one personal collection.
class SavedAlbumScreen extends StatelessWidget {
  const SavedAlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HangoutRepository.instance,
      builder: (context, _) {
        final repo = HangoutRepository.instance;
        final photos = repo.savedPhotos;
        final savedBytes = photos.fold<int>(
          0,
          (sum, p) => sum + p.optimizedSizeBytes,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: ListView(
              padding: EdgeInsets.fromLTRB(
                  0, MediaQuery.paddingOf(context).top + 8, 0, 40),
              children: [
                AppScreenHeader(
                  title: 'Saved',
                  subtitle:
                      '${photos.length} PHOTOS · ${(savedBytes / (1024 * 1024)).toStringAsFixed(1)} MB LOCAL',
                  onBack: () => Navigator.maybePop(context),
                ),
                if (photos.isEmpty)
                  const _EmptySaved()
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, i) =>
                          _SavedTile(photo: photos[i]),
                    ),
                  ),
              ],
            ),
        );
      },
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Panel(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(Icons.bookmark_border,
                  size: 40, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'Nothing saved yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Like or download a photo in any event share and it will\ncollect here — ready to save before the 14-day prune.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  final PhotoItem photo;

  const _SavedTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => HangoutRepository.instance.togglePhotoLike(photo.id),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusPanel),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ResilientImage(source: photo.imageUrl, fit: BoxFit.cover),
                    if (photo.isLiked)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.jetBlack,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 12,
                            color: AppColors.neonLime,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.uploaderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${photo.optimizedSizeFormatted} WEBP',
                      style: AppTheme.mono(
                        size: 9,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
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
