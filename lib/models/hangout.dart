import 'package:flutter/material.dart';

import 'attendee.dart';
import 'photo_item.dart';

/// An event share: a collaborative photo album that auto-routes photos to
/// the attendees detected in them via on-device face recognition.
class Hangout {
  final String id;
  final String title;
  final String category;
  final String location;
  final String dateDescription;
  final String heroImageUrl;
  final String inviteCode; // 4-digit Tap-to-Share PIN (e.g. 8492)
  final String description;
  final int ttlDaysRemaining;
  final Color accentColor;
  final List<Attendee> attendees;
  final List<PhotoItem> photos;

  /// Where on Earth this share happened — pins it on the home globe.
  /// Null for shares created without a place.
  final double? latitude;
  final double? longitude;

  /// Optional host-linked Google Drive folder (`AutoShare/[EventName]`).
  /// Null means the event relies purely on the free Cloudflare R2 tier.
  final String? driveFolderName;

  // ---- Host controls / guest roles ----------------------------------------

  /// Id of the attendee who created and controls this share.
  final String hostId;

  /// When true, newly uploaded photos of an attendee wait in their Consent
  /// Vault instead of going straight to the public album.
  final bool ghostModeDefault;

  /// When true, any guest may invite others with the QR/NFC pass.
  final bool guestsCanInvite;

  /// When true, any guest may contribute photos; otherwise only the host can.
  final bool guestsCanPost;

  /// When true, only approved photos are visible to everyone (private stays
  /// private); when false, the host sees every photo.
  final bool requireApprovalToPublish;

  Hangout({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.dateDescription,
    required this.heroImageUrl,
    this.inviteCode = '8492',
    this.description = '',
    this.ttlDaysRemaining = 14,
    this.accentColor = const Color(0xFFC7B8FB),
    this.attendees = const [],
    this.photos = const [],
    this.latitude,
    this.longitude,
    this.driveFolderName,
    this.hostId = '',
    this.ghostModeDefault = true,
    this.guestsCanInvite = true,
    this.guestsCanPost = true,
    this.requireApprovalToPublish = true,
  });

  /// True when the host linked their free 15 GB Google Drive as an event backup.
  bool get isDriveLinked => driveFolderName != null;

  /// True when [attendeeId] owns this share.
  bool isHost(String attendeeId) => hostId == attendeeId;

  /// Days left before the ephemeral cloud copies are pruned.
  bool get isExpiringSoon => ttlDaysRemaining <= 3;

  String get ttlLabel => ttlDaysRemaining <= 0
      ? 'Pruning now'
      : '$ttlDaysRemaining day${ttlDaysRemaining == 1 ? '' : 's'} left';

  /// Human-readable storage line shown in event shares.
  String get storageSummary => isDriveLinked
      ? 'Cloudflare R2 + Google Drive ($driveFolderName)'
      : 'Cloudflare R2 (Free 10 GB tier)';

  int get contributorsCount {
    final uploaders = photos.map((p) => p.uploaderName).toSet();
    return uploaders.isEmpty ? 1 : uploaders.length;
  }

  int get totalFacesDetected {
    int total = 0;
    for (final p in photos) {
      total += p.detectedAttendeeIds.length;
    }
    return total;
  }

  List<PhotoItem> get publicPhotos {
    return photos.where((p) => p.isApprovedForPublicGallery).toList();
  }

  int photosCountForAttendee(String attendeeId) {
    return photos.where((p) => p.detectedAttendeeIds.contains(attendeeId)).length;
  }

  /// Photos waiting in this share's Consent Vault for the given attendee.
  List<PhotoItem> pendingConsentPhotosFor(String attendeeId) {
    return photos
        .where((p) =>
            p.requiresConsent &&
            !p.isKeptPrivateByUser &&
            p.detectedAttendeeIds.contains(attendeeId))
        .toList();
  }

  Hangout copyWith({
    String? title,
    String? category,
    String? location,
    String? dateDescription,
    String? heroImageUrl,
    String? inviteCode,
    String? description,
    int? ttlDaysRemaining,
    Color? accentColor,
    List<Attendee>? attendees,
    List<PhotoItem>? photos,
    double? latitude,
    double? longitude,
    String? driveFolderName,
    bool clearDriveFolder = false,
    String? hostId,
    bool? ghostModeDefault,
    bool? guestsCanInvite,
    bool? guestsCanPost,
    bool? requireApprovalToPublish,
  }) {
    return Hangout(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      location: location ?? this.location,
      dateDescription: dateDescription ?? this.dateDescription,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      inviteCode: inviteCode ?? this.inviteCode,
      description: description ?? this.description,
      ttlDaysRemaining: ttlDaysRemaining ?? this.ttlDaysRemaining,
      accentColor: accentColor ?? this.accentColor,
      attendees: attendees ?? this.attendees,
      photos: photos ?? this.photos,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      driveFolderName: clearDriveFolder
          ? null
          : (driveFolderName ?? this.driveFolderName),
      hostId: hostId ?? this.hostId,
      ghostModeDefault: ghostModeDefault ?? this.ghostModeDefault,
      guestsCanInvite: guestsCanInvite ?? this.guestsCanInvite,
      guestsCanPost: guestsCanPost ?? this.guestsCanPost,
      requireApprovalToPublish:
          requireApprovalToPublish ?? this.requireApprovalToPublish,
    );
  }
}