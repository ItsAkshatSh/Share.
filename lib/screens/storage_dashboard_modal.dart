import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/hangout_repository.dart';
import '../services/storage_optimizer_service.dart';

class StorageDashboardModal extends StatelessWidget {
  const StorageDashboardModal({super.key});

  @override
  Widget build(BuildContext context) {
    final hangouts = HangoutRepository.instance.hangouts;
    int totalPhotos = 0;
    for (final h in hangouts) {
      totalPhotos += h.photos.length;
    }

    final metrics = StorageOptimizerService.instance.calculateMetrics(
      photoCount: totalPhotos > 0 ? totalPhotos : 12,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill grabber
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zero-Cost Storage Engine',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'How we keep high-res sharing completely free',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                  icon: Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Hero Savings Card (Lilac + Lime)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.softLilac,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Storage Reduction',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '97.4% SAVED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        metrics.savedFormatted,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'cloud space saved',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Raw original photos (${metrics.originalFormatted}) were compressed on-device into retina-sharp WebP (${metrics.optimizedFormatted}) before leaving your phone.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3-Pillar Solution Breakdown
            _buildStrategyTile(
              icon: Icons.cloud_done_outlined,
              title: '1. Cloudflare R2 (Free 10 GB)',
              subtitle:
                  'AWS S3 charges \$0.09/GB to download photos. Cloudflare R2 has \$0.00 egress bandwidth fees forever. 10GB stores ~40,000 photos for free.',
              badge: '\$0 Egress',
            ),
            const SizedBox(height: 10),
            _buildStrategyTile(
              icon: Icons.timer_outlined,
              title: '2. Ephemeral TTL Auto-Pruning',
              subtitle:
                  'Hangouts stay live for 14-30 days. Attendees are prompted to save favorites to camera roll before cloud pruning, recycling your free tier indefinitely.',
              badge: '14-Day Cycle',
            ),
            const SizedBox(height: 10),
            _buildStrategyTile(
              icon: Icons.wifi_tethering_outlined,
              title: '3. Nearby P2P Direct Sync',
              subtitle:
                  'When friends are physically at the same meetup, full-resolution RAW photos transfer directly via Local Wi-Fi / Hotspot with zero cloud usage.',
              badge: 'Direct Sync',
            ),

            const SizedBox(height: 24),

            // Action
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jetBlack,
                  foregroundColor: AppColors.onDarkChrome,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.jetBlack),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.3,
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
