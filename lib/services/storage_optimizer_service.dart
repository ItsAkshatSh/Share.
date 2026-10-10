/// Handles photo compression simulation, storage efficiency metrics,
/// and Cloudflare R2 zero-egress management.
class StorageMetrics {
  final int totalOriginalBytes;
  final int totalOptimizedBytes;
  final int photosCount;
  final double egressCostSavedUsd;

  const StorageMetrics({
    required this.totalOriginalBytes,
    required this.totalOptimizedBytes,
    required this.photosCount,
    required this.egressCostSavedUsd,
  });

  int get bytesSaved => totalOriginalBytes - totalOptimizedBytes;

  double get percentageSaved {
    if (totalOriginalBytes == 0) return 0.0;
    return (bytesSaved / totalOriginalBytes) * 100;
  }

  String get originalFormatted =>
      '${(totalOriginalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  String get optimizedFormatted =>
      '${(totalOptimizedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  String get savedFormatted =>
      '${(bytesSaved / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class StorageOptimizerService {
  StorageOptimizerService._();
  static final StorageOptimizerService instance = StorageOptimizerService._();

  // Cloudflare R2 free tier limit: 10 GB
  static const int r2FreeTierBytes = 10 * 1024 * 1024 * 1024;

  StorageMetrics calculateMetrics({
    required int photoCount,
    int avgOriginalBytes = 9400000, // ~9.4 MB
    int avgOptimizedBytes = 245000, // ~245 KB (WebP 82% @ 1440p)
  }) {
    final totalOrig = photoCount * avgOriginalBytes;
    final totalOpt = photoCount * avgOptimizedBytes;

    // Standard AWS S3 egress charge is ~$0.09 / GB.
    // Cloudflare R2 egress is $0.00 / GB.
    // If each photo is viewed/downloaded by 6 attendees:
    final totalDownloadedBytes = totalOpt * 6;
    final savedEgressUsd = (totalDownloadedBytes / (1024 * 1024 * 1024)) * 0.09;

    return StorageMetrics(
      totalOriginalBytes: totalOrig,
      totalOptimizedBytes: totalOpt,
      photosCount: photoCount,
      egressCostSavedUsd: savedEgressUsd,
    );
  }
}
