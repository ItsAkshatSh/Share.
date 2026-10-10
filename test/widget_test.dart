import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:share/services/face_recognition_service.dart';
import 'package:share/services/google_auth_service.dart';
import 'package:share/services/hangout_repository.dart';
import 'package:share/models/photo_item.dart';
import 'package:share/services/nfc_service.dart';
import 'package:share/services/storage_optimizer_service.dart';

void main() {
  setUp(() async {
    // Shared singletons: reset so tests don't depend on execution order.
    HangoutRepository.instance.reset();
    await GoogleAuthService.instance.switchDemoAccount(0);
  });

  group('GoogleAuthService Tests', () {
    test('Demo sign-in provides profile and face vector', () {
      final auth = GoogleAuthService.instance;
      expect(auth.isSignedIn, isTrue);
      expect(auth.currentUser?.name, contains('Jannes'));
      expect(auth.currentUser?.faceVector, isNotNull);
      expect(auth.currentUser?.faceVector?.length, 128);
    });

    test('Account switching updates current user and face embedding', () async {
      final auth = GoogleAuthService.instance;
      await auth.switchDemoAccount(1); // Sarah Chen
      expect(auth.currentUser?.name, 'Sarah Chen');
      expect(auth.currentUser?.faceVector?.length, 128);
      
      // Reset back to Jannes
      await auth.switchDemoAccount(0);
      expect(auth.currentUser?.name, 'Jannes Miller');
    });
  });

  group('Consent Vault Tests', () {
    test('Pending photos require consent before public display', () {
      final repo = HangoutRepository.instance;
      final pending = repo.pendingConsentPhotos;
      expect(pending, isNotEmpty);

      final photoToApprove = pending.first;
      expect(photoToApprove.isApprovedForPublicGallery, isFalse);

      repo.approvePhotoForPublic(photoToApprove.id);
      expect(photoToApprove.isApprovedForPublicGallery, isTrue);
      expect(photoToApprove.requiresConsent, isFalse);
    });

    test('Keeping photo private hides it from public album', () {
      final repo = HangoutRepository.instance;
      final pending = repo.pendingConsentPhotos;
      if (pending.isNotEmpty) {
        final photoToKeepPrivate = pending.first;
        repo.keepPhotoPrivate(photoToKeepPrivate.id);
        expect(photoToKeepPrivate.isKeptPrivateByUser, isTrue);
        expect(photoToKeepPrivate.isApprovedForPublicGallery, isFalse);
      }
    });
  });

  group('Ghost Mode per-user consent map', () {
    test('Approval records an individual decision for the current user', () {
      final repo = HangoutRepository.instance;
      final pending = repo.pendingConsentPhotos;
      expect(pending, isNotEmpty);

      final photo = pending.first;
      final uid = repo.currentUser!.id;
      expect(photo.consentDecisionFor(uid), ConsentDecision.pending);

      repo.approvePhotoForPublic(photo.id);
      expect(photo.approvalStatus[uid], ConsentDecision.approved);
      expect(photo.isApprovedByTaggedUsers, isTrue);
    });

    test('Keeping private records a keptPrivate decision', () {
      final repo = HangoutRepository.instance;
      final pending = repo.pendingConsentPhotos;
      if (pending.isNotEmpty) {
        final photo = pending.first;
        repo.keepPhotoPrivate(photo.id);
        expect(photo.approvalStatus[repo.currentUser!.id],
            ConsentDecision.keptPrivate);
      }
    });
  });

  group('Event share repository', () {
    test('Ships the three planned social event shares', () {
      final repo = HangoutRepository.instance;
      final ids = repo.hangouts.map((h) => h.id).toList();
      expect(ids, containsAll(['event_rooftop', 'event_birthday', 'event_lakehouse']));
    });

    test('Host can link and unlink a Google Drive folder', () {
      final repo = HangoutRepository.instance;
      repo.setDriveFolder('event_lakehouse', 'AutoShare/Lake House Summer Trip');
      expect(repo.hangouts.firstWhere((h) => h.id == 'event_lakehouse').isDriveLinked,
          isTrue);

      repo.setDriveFolder('event_lakehouse', null);
      expect(repo.hangouts.firstWhere((h) => h.id == 'event_lakehouse').isDriveLinked,
          isFalse);
    });

    test('copyWith preserves identity and updates photos', () {
      final repo = HangoutRepository.instance;
      final hangout = repo.hangouts.first;
      final updated = hangout.copyWith(photos: hangout.photos);
      expect(updated.id, hangout.id);
      expect(updated.driveFolderName, hangout.driveFolderName);
    });
  });

  group('Tap-to-Share join', () {
    test('Invite URI is a scannable deep link containing the PIN', () {
      final repo = HangoutRepository.instance;
      final hangout = repo.hangouts.first;
      expect(repo.inviteUriFor(hangout),
          'https://autoshare.app/share/${hangout.inviteCode}');
    });

    test('Extracts a PIN from both a bare code and a deep link', () {
      expect(HangoutRepository.extractInviteCode('8492'), '8492');
      expect(HangoutRepository.extractInviteCode('https://autoshare.app/share/5913'),
          '5913');
      expect(HangoutRepository.extractInviteCode('no code here'), isNull);
    });

    test('Joining by PIN adds the user and selects the share', () {
      final repo = HangoutRepository.instance;
      final joined = repo.joinEventByCode('https://autoshare.app/share/2377');
      expect(joined, isNotNull);
      expect(joined!.id, 'event_lakehouse');
      expect(repo.selectedHangout.id, 'event_lakehouse');
      expect(joined.attendees.any((a) => a.id == repo.currentUser!.id), isTrue);
    });

    test('Unknown PIN returns null', () {
      expect(HangoutRepository.instance.joinEventByCode('0000'), isNull);
    });
  });

  group('NFC NDEF URI codec', () {
    test('Round-trips an https invite URI through an NDEF record', () {
      const uri = 'https://autoshare.app/share/8492';
      final record = NfcService.buildUriRecord(uri);

      expect(record.type, [0x55]); // well-known 'U'
      expect(record.payload.first, 0x04); // https:// prefix code
      expect(NfcService.decodeUriRecord(record.type, record.payload), uri);
    });

    test('Round-trips a plain http URI (prefix 0x03)', () {
      const uri = 'http://autoshare.app/share/1234';
      final record = NfcService.buildUriRecord(uri);
      expect(record.payload.first, 0x03);
      expect(NfcService.decodeUriRecord(record.type, record.payload), uri);
    });

    test('Non-URI records decode to null', () {
      final notUri = NfcService.buildUriRecord('https://x.dev');
      expect(
        NfcService.decodeUriRecord(
          Uint8List.fromList([0x54]), // 'T' text record
          notUri.payload,
        ),
        isNull,
      );
    });
  });

  group('FaceRecognitionService Unit Tests', () {
    test('Cosine similarity matches identical vectors with 1.0', () {
      final service = FaceRecognitionService.instance;
      final vecA = [0.5, 0.5, 0.5, 0.5];
      final similarity = service.computeCosineSimilarity(vecA, vecA);
      expect(similarity, closeTo(1.0, 0.0001));
    });

    test('Cosine similarity handles orthogonal vectors with 0.0', () {
      final service = FaceRecognitionService.instance;
      final vecA = [1.0, 0.0, 0.0];
      final vecB = [0.0, 1.0, 0.0];
      final similarity = service.computeCosineSimilarity(vecA, vecB);
      expect(similarity, closeTo(0.0, 0.0001));
    });
  });

  group('StorageOptimizerService Unit Tests', () {
    test('Calculates 97%+ reduction with WebP compression', () {
      final optimizer = StorageOptimizerService.instance;
      final metrics = optimizer.calculateMetrics(photoCount: 50);

      expect(metrics.photosCount, 50);
      expect(metrics.percentageSaved, greaterThan(95.0));
    });
  });
}
