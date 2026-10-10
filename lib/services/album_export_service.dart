import 'package:share_plus/share_plus.dart';

import '../models/hangout.dart';
import 'storage_optimizer_service.dart';

/// Builds the human-readable event summary and hands it to the OS share sheet.
class AlbumExportService {
  AlbumExportService._();
  static final AlbumExportService instance = AlbumExportService._();

  /// A plain-text summary of a share: counts, guests, storage saved.
  String buildSummary(Hangout hangout) {
    final metrics = StorageOptimizerService.instance.calculateMetrics(
      photoCount: hangout.photos.length,
    );

    final guests = hangout.attendees
        .map((a) => '  • ${a.name}${hangout.isHost(a.id) ? ' (host)' : ''}')
        .join('\n');

    return '''
${hangout.title.replaceAll('\n', ' ')}
${hangout.category} · ${hangout.dateDescription}
${hangout.location}

${hangout.publicPhotos.length} public photos · ${hangout.contributorsCount} contributors
${hangout.totalFacesDetected} faces auto-tagged · ${hangout.attendees.length} guests
${hangout.ttlLabel} before cloud copies are pruned

Storage: ${metrics.savedFormatted} saved vs originals (${metrics.percentageSaved.toStringAsFixed(1)}% reduction)
Cloud: ${hangout.storageSummary}

Guests:
$guests

Invite pass: https://autoshare.app/share/${hangout.inviteCode}
''';
  }

  /// Opens the platform share sheet with the summary.
  Future<void> shareSummary(Hangout hangout) async {
    await SharePlus.instance.share(
      ShareParams(
        text: buildSummary(hangout),
        subject: '${hangout.title.replaceAll('\n', ' ')} — event summary',
      ),
    );
  }

  /// Shares just the invite link.
  Future<void> shareInviteLink(Hangout hangout) async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Join "${hangout.title.replaceAll('\n', ' ')}" on AutoShare: '              'https://autoshare.app/share/${hangout.inviteCode}',
      ),
    );
  }
}
