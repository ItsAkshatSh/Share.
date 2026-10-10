    class DetectedFaceBox {
  final String attendeeId;
  final String attendeeName;
  final double x; // normalized 0..1
  final double y;
  final double width;
  final double height;
  final double confidence;

  const DetectedFaceBox({
    required this.attendeeId,
    required this.attendeeName,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence = 0.96,
  });
}

/// Ghost Mode consent decision for a single tagged attendee.
enum ConsentDecision { pending, approved, keptPrivate }

class PhotoItem {
  final String id;
  final String hangoutId;
  final String imageUrl;
  final String uploaderName;
  final String uploaderAvatar;
  final List<String> detectedAttendeeIds;
  final List<DetectedFaceBox> faceBoxes;
  final int originalSizeBytes; // in bytes (e.g. 10.4MB)
  final int optimizedSizeBytes; // in bytes (e.g. 240KB WebP)
  final DateTime timestamp;
  bool isLiked;
  bool isSavedLocally;

  // Ghost Mode & Private Consent Vault status
  bool isApprovedForPublicGallery;
  bool requiresConsent;
  bool isKeptPrivateByUser;

  /// Per-attendee consent decision, keyed by attendee id. Absent entries fall
  /// back to the photo-level [isApprovedForPublicGallery] flag.
  final Map<String, ConsentDecision> approvalStatus;

  PhotoItem({
    required this.id,
    required this.hangoutId,
    required this.imageUrl,
    required this.uploaderName,
    required this.uploaderAvatar,
    this.detectedAttendeeIds = const [],
    this.faceBoxes = const [],
    this.originalSizeBytes = 9400000,
    this.optimizedSizeBytes = 245000,
    DateTime? timestamp,
    this.isLiked = false,
    this.isSavedLocally = false,
    this.isApprovedForPublicGallery = true,
    this.requiresConsent = false,
    this.isKeptPrivateByUser = false,
    Map<String, ConsentDecision>? approvalStatus,
  })  : approvalStatus = Map<String, ConsentDecision>.of(
          approvalStatus ?? const <String, ConsentDecision>{},
        ),
        timestamp = timestamp ?? DateTime.now();

  /// True when every tagged attendee has approved (or consent is not needed).
  bool get isApprovedByTaggedUsers {
    if (!requiresConsent) return true;
    return detectedAttendeeIds.every(
      (id) => approvalStatus[id] == ConsentDecision.approved,
    );
  }

  ConsentDecision consentDecisionFor(String attendeeId) {
    return approvalStatus[attendeeId] ??
        (isApprovedForPublicGallery
            ? ConsentDecision.approved
            : ConsentDecision.pending);
  }

  double get spaceSavedRatio {
    if (originalSizeBytes <= 0) return 0.0;
    return (originalSizeBytes - optimizedSizeBytes) / originalSizeBytes;
  }

  String get originalSizeFormatted {
    return '${(originalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get optimizedSizeFormatted {
    return '${(optimizedSizeBytes / 1024).toStringAsFixed(0)} KB';
  }
}