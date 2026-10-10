import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/attendee.dart';
import '../models/hangout.dart';
import '../models/photo_item.dart';
import '../services/face_recognition_service.dart';

/// JSON encode/decode for shares stored on device.
class HangoutCodec {
  HangoutCodec._();

  static String encodeState({
    required List<Hangout> hangouts,
    required String selectedHangoutId,
  }) {
    return jsonEncode({
      'version': 1,
      'selectedHangoutId': selectedHangoutId,
      'hangouts': hangouts.map(_hangoutToJson).toList(),
    });
  }

  static ({List<Hangout> hangouts, String selectedHangoutId})? decodeState(
    String raw,
  ) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final hangouts = (map['hangouts'] as List<dynamic>)
          .map((e) => _hangoutFromJson(e as Map<String, dynamic>))
          .toList();
      return (
        hangouts: hangouts,
        selectedHangoutId: map['selectedHangoutId'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _hangoutToJson(Hangout h) => {
        'id': h.id,
        'title': h.title,
        'category': h.category,
        'location': h.location,
        'dateDescription': h.dateDescription,
        'heroImageUrl': h.heroImageUrl,
        'inviteCode': h.inviteCode,
        'description': h.description,
        'ttlDaysRemaining': h.ttlDaysRemaining,
        'accentColor': h.accentColor.value,
        'latitude': h.latitude,
        'longitude': h.longitude,
        'driveFolderName': h.driveFolderName,
        'hostId': h.hostId,
        'ghostModeDefault': h.ghostModeDefault,
        'guestsCanInvite': h.guestsCanInvite,
        'guestsCanPost': h.guestsCanPost,
        'requireApprovalToPublish': h.requireApprovalToPublish,
        'attendees': h.attendees.map(_attendeeToJson).toList(),
        'photos': h.photos.map(_photoToJson).toList(),
      };

  static Hangout _hangoutFromJson(Map<String, dynamic> m) => Hangout(
        id: m['id'] as String,
        title: m['title'] as String,
        category: m['category'] as String? ?? 'Event',
        location: m['location'] as String? ?? '',
        dateDescription: m['dateDescription'] as String? ?? '',
        heroImageUrl: m['heroImageUrl'] as String? ?? '',
        inviteCode: m['inviteCode'] as String? ?? '0000',
        description: m['description'] as String? ?? '',
        ttlDaysRemaining: m['ttlDaysRemaining'] as int? ?? 14,
        accentColor: Color(m['accentColor'] as int? ?? 0xFFC7B8FB),
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        driveFolderName: m['driveFolderName'] as String?,
        hostId: m['hostId'] as String? ?? '',
        ghostModeDefault: m['ghostModeDefault'] as bool? ?? true,
        guestsCanInvite: m['guestsCanInvite'] as bool? ?? true,
        guestsCanPost: m['guestsCanPost'] as bool? ?? true,
        requireApprovalToPublish:
            m['requireApprovalToPublish'] as bool? ?? true,
        attendees: (m['attendees'] as List<dynamic>?)
                ?.map((e) => _attendeeFromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        photos: (m['photos'] as List<dynamic>?)
                ?.map((e) => _photoFromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  static Map<String, dynamic> _attendeeToJson(Attendee a) => {
        'id': a.id,
        'name': a.name,
        'avatarUrl': a.avatarUrl,
        'subtitle': a.subtitle,
        'followersCount': a.followersCount,
        'faceVector': a.faceVector,
        'isCurrentUser': a.isCurrentUser,
        'isFollowing': a.isFollowing,
      };

  static Attendee _attendeeFromJson(Map<String, dynamic> m) => Attendee(
        id: m['id'] as String,
        name: m['name'] as String,
        avatarUrl: m['avatarUrl'] as String,
        subtitle: m['subtitle'] as String? ?? '',
        followersCount: m['followersCount'] as String? ?? '',
        faceVector: (m['faceVector'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
        isCurrentUser: m['isCurrentUser'] as bool? ?? false,
        isFollowing: m['isFollowing'] as bool? ?? false,
      );

  static Map<String, dynamic> _photoToJson(PhotoItem p) => {
        'id': p.id,
        'hangoutId': p.hangoutId,
        'imageUrl': p.imageUrl,
        'uploaderName': p.uploaderName,
        'uploaderAvatar': p.uploaderAvatar,
        'detectedAttendeeIds': p.detectedAttendeeIds,
        'faceBoxes': p.faceBoxes.map(_faceBoxToJson).toList(),
        'originalSizeBytes': p.originalSizeBytes,
        'optimizedSizeBytes': p.optimizedSizeBytes,
        'timestamp': p.timestamp.toIso8601String(),
        'isLiked': p.isLiked,
        'isSavedLocally': p.isSavedLocally,
        'isApprovedForPublicGallery': p.isApprovedForPublicGallery,
        'requiresConsent': p.requiresConsent,
        'isKeptPrivateByUser': p.isKeptPrivateByUser,
        'approvalStatus': p.approvalStatus.map(
          (k, v) => MapEntry(k, v.name),
        ),
      };

  static PhotoItem _photoFromJson(Map<String, dynamic> m) {
    final statusRaw = m['approvalStatus'] as Map<String, dynamic>? ?? {};
    final status = <String, ConsentDecision>{};
    for (final e in statusRaw.entries) {
      status[e.key] = ConsentDecision.values.firstWhere(
        (d) => d.name == e.value,
        orElse: () => ConsentDecision.pending,
      );
    }

    return PhotoItem(
      id: m['id'] as String,
      hangoutId: m['hangoutId'] as String,
      imageUrl: m['imageUrl'] as String,
      uploaderName: m['uploaderName'] as String,
      uploaderAvatar: m['uploaderAvatar'] as String,
      detectedAttendeeIds:
          (m['detectedAttendeeIds'] as List<dynamic>).cast<String>(),
      faceBoxes: (m['faceBoxes'] as List<dynamic>?)
              ?.map((e) => _faceBoxFromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      originalSizeBytes: m['originalSizeBytes'] as int? ?? 0,
      optimizedSizeBytes: m['optimizedSizeBytes'] as int? ?? 0,
      timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isLiked: m['isLiked'] as bool? ?? false,
      isSavedLocally: m['isSavedLocally'] as bool? ?? false,
      isApprovedForPublicGallery:
          m['isApprovedForPublicGallery'] as bool? ?? true,
      requiresConsent: m['requiresConsent'] as bool? ?? false,
      isKeptPrivateByUser: m['isKeptPrivateByUser'] as bool? ?? false,
      approvalStatus: status,
    );
  }

  static Map<String, dynamic> _faceBoxToJson(DetectedFaceBox b) => {
        'attendeeId': b.attendeeId,
        'attendeeName': b.attendeeName,
        'x': b.x,
        'y': b.y,
        'width': b.width,
        'height': b.height,
        'confidence': b.confidence,
      };

  static DetectedFaceBox _faceBoxFromJson(Map<String, dynamic> m) =>
      DetectedFaceBox(
        attendeeId: m['attendeeId'] as String,
        attendeeName: m['attendeeName'] as String,
        x: (m['x'] as num).toDouble(),
        y: (m['y'] as num).toDouble(),
        width: (m['width'] as num).toDouble(),
        height: (m['height'] as num).toDouble(),
        confidence: (m['confidence'] as num?)?.toDouble() ?? 0.96,
      );

  static String encodeUser(Attendee user) => jsonEncode(_attendeeToJson(user));

  static Attendee? decodeUser(String raw) {
    try {
      return _attendeeFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Ensures restored users always have a face vector for tagging.
  static Attendee ensureFaceVector(Attendee user) {
    if (user.faceVector != null && user.faceVector!.length == 128) {
      return user;
    }
    return user.copyWith(
      faceVector: FaceRecognitionService.instance
          .generateSimulatedVector(user.avatarUrl),
    );
  }
}
