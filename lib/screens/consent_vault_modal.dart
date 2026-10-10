import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../models/photo_item.dart';
import '../services/hangout_repository.dart';
import '../widgets/resilient_image.dart';

/// "Next steps"-style sheet: raised dark cards on the pure-black page.
class ConsentVaultModal extends StatefulWidget {
  const ConsentVaultModal({super.key});

  @override
  State<ConsentVaultModal> createState() => _ConsentVaultModalState();
}

class _ConsentVaultModalState extends State<ConsentVaultModal> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HangoutRepository.instance,
      builder: (context, _) {
        final pendingPhotos = HangoutRepository.instance.pendingConsentPhotos;
        final topInset = MediaQuery.paddingOf(context).top;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, topInset > 40 ? 18 : 26, 20, 30),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ghost Mode',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Text(
                'Review photos of you before they go public',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              if (pendingPhotos.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.shield_outlined,
                                size: 36, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Your Vault is Clear!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No unapproved photos of you are pending.\nGhost Mode is actively shielding your candid angles.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: pendingPhotos.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final photo = pendingPhotos[idx];
                      return _buildConsentCard(photo);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsentCard(PhotoItem photo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taken by ${photo.uploaderName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You were detected in this photo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _VaultAction(
                      label: 'Approve',
                      icon: Icons.check_outlined,
                      filled: true,
                      onTap: () =>
                          HangoutRepository.instance.approvePhotoForPublic(
                        photo.id,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _VaultAction(
                      label: 'Keep private',
                      icon: Icons.lock_outline,
                      onTap: () =>
                          HangoutRepository.instance.keepPhotoPrivate(photo.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 92,
              height: 92,
              child: ResilientImage(source: photo.imageUrl, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _VaultAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      haptic: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: filled ? AppColors.onAccent : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: filled ? AppColors.onAccent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
