import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants/sample_data.dart';
import '../models/attendee.dart';
import '../models/hangout.dart';
import '../models/photo_item.dart';
import 'face_recognition_service.dart';
import 'google_auth_service.dart';
import 'hangout_store.dart';

class HangoutRepository extends ChangeNotifier {
  HangoutRepository._();
  static final HangoutRepository instance = HangoutRepository._();

  List<Hangout> _hangouts = [];
  String _selectedHangoutId = '';
  bool _isScanning = false;
  bool _loaded = false;

  Attendee? get currentUser => GoogleAuthService.instance.currentUser;

  List<Hangout> get hangouts => List.unmodifiable(_hangouts);
  bool get isScanning => _isScanning;
  bool get isLoaded => _loaded;

  Hangout? get selectedHangoutOrNull {
    if (_hangouts.isEmpty) return null;
    return _hangouts.firstWhere(
      (h) => h.id == _selectedHangoutId,
      orElse: () => _hangouts.first,
    );
  }

  Hangout get selectedHangout {
    final h = selectedHangoutOrNull;
    if (h == null) {
      throw StateError('No event share selected');
    }
    return h;
  }

  Future<void> load() async {
    final stored = await HangoutStore.load();
    if (stored != null && stored.hangouts.isNotEmpty) {
      _hangouts = stored.hangouts;
      _selectedHangoutId = stored.selectedHangoutId;
      if (!_hangouts.any((h) => h.id == _selectedHangoutId)) {
        _selectedHangoutId = _hangouts.first.id;
      }
    } else {
      // First run, or nothing share-worthy saved — show the demo shares so
      // the home feed and the world globe start with real content.
      _hangouts = SampleData.getSampleEvents();
      _selectedHangoutId = _hangouts.first.id;
    }

    GoogleAuthService.instance.addListener(_onAuthChanged);
    _loaded = true;
    notifyListeners();
  }

  void _onAuthChanged() {
    notifyListeners();
  }

  void _persist() {
    HangoutStore.save(
      hangouts: _hangouts,
      selectedHangoutId: _selectedHangoutId,
    );
  }

  void _touch() {
    _persist();
    notifyListeners();
  }

  Hangout createShare({
    required String title,
    String category = 'Event',
    String location = '',
  }) {
    final user = currentUser;
    if (user == null) {
      throw StateError('Sign in to create a share');
    }

    final id = 'event_${DateTime.now().millisecondsSinceEpoch}';
    final hangout = Hangout(
      id: id,
      title: title.replaceAll('\n', ' '),
      category: category,
      location: location,
      dateDescription: _todayLabel(),
      heroImageUrl: '',
      inviteCode: _uniqueInviteCode(),
      description: '',
      ttlDaysRemaining: 14,
      accentColor: _accentForIndex(_hangouts.length),
      hostId: user.id,
      attendees: [user.copyWith(isCurrentUser: true)],
      photos: const [],
    );

    _hangouts = [hangout, ..._hangouts];
    _selectedHangoutId = id;
    _touch();
    return hangout;
  }

  void selectHangout(String id) {
    _selectedHangoutId = id;
    _touch();
  }

  void updateHostControls(
    String hangoutId, {
    bool? ghostModeDefault,
    bool? guestsCanInvite,
    bool? guestsCanPost,
    bool? requireApprovalToPublish,
  }) {
    final index = _hangouts.indexWhere((h) => h.id == hangoutId);
    if (index == -1) return;
    _hangouts[index] = _hangouts[index].copyWith(
      ghostModeDefault: ghostModeDefault,
      guestsCanInvite: guestsCanInvite,
      guestsCanPost: guestsCanPost,
      requireApprovalToPublish: requireApprovalToPublish,
    );
    _touch();
  }

  List<PhotoItem> get savedPhotos {
    final list = <PhotoItem>[];
    for (final h in _hangouts) {
      for (final p in h.photos) {
        if (p.isLiked || p.isSavedLocally) list.add(p);
      }
    }
    return list;
  }

  List<Attendee> get allAttendees {
    final byId = <String, Attendee>{};
    for (final h in _hangouts) {
      for (final a in h.attendees) {
        byId.putIfAbsent(a.id, () => a);
      }
    }
    return byId.values.toList();
  }

  ({List<Hangout> events, List<Attendee> people}) search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return (events: const <Hangout>[], people: const <Attendee>[]);
    }
    return (
      events: _hangouts
          .where((h) =>
              h.title.toLowerCase().contains(q) ||
              h.category.toLowerCase().contains(q) ||
              h.location.toLowerCase().contains(q))
          .toList(),
      people: allAttendees
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.subtitle.toLowerCase().contains(q))
          .toList(),
    );
  }

  String inviteUriFor(Hangout hangout) =>
      'https://autoshare.app/share/${hangout.inviteCode}';

  String get selectedInviteUri {
    final h = selectedHangoutOrNull;
    if (h == null) return '';
    return inviteUriFor(h);
  }

  Hangout? joinEventByCode(String payload) {
    final user = currentUser;
    if (user == null) return null;

    final code = extractInviteCode(payload);
    if (code == null) return null;

    final index = _hangouts.indexWhere((h) => h.inviteCode == code);
    if (index == -1) return null;

    final hangout = _hangouts[index];
    final alreadyIn = hangout.attendees.any((a) => a.id == user.id);
    if (!alreadyIn) {
      _hangouts[index] =
          hangout.copyWith(attendees: [...hangout.attendees, user]);
    }

    _selectedHangoutId = _hangouts[index].id;
    _touch();
    return _hangouts[index];
  }

  static String? extractInviteCode(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return null;

    final match = RegExp(r'(\d{4})').firstMatch(trimmed);
    return match?.group(1);
  }

  @visibleForTesting
  void reset() {
    _hangouts = SampleData.getSampleEvents();
    _selectedHangoutId = 'event_rooftop';
    _touch();
  }

  List<PhotoItem> get pendingConsentPhotos {
    final user = currentUser;
    if (user == null) return const [];

    final list = <PhotoItem>[];
    for (final h in _hangouts) {
      for (final p in h.photos) {
        if (p.requiresConsent &&
            !p.isApprovedForPublicGallery &&
            !p.isKeptPrivateByUser &&
            p.detectedAttendeeIds.contains(user.id)) {
          list.add(p);
        }
      }
    }
    return list;
  }

  void approvePhotoForPublic(String photoId) {
    final user = currentUser;
    if (user == null) return;

    for (final h in _hangouts) {
      for (final p in h.photos) {
        if (p.id == photoId) {
          p.approvalStatus[user.id] = ConsentDecision.approved;
          p.isApprovedForPublicGallery = true;
          p.requiresConsent = false;
        }
      }
    }
    _touch();
  }

  void keepPhotoPrivate(String photoId) {
    final user = currentUser;
    if (user == null) return;

    for (final h in _hangouts) {
      for (final p in h.photos) {
        if (p.id == photoId) {
          p.approvalStatus[user.id] = ConsentDecision.keptPrivate;
          p.isKeptPrivateByUser = true;
          p.requiresConsent = false;
          p.isSavedLocally = true;
        }
      }
    }
    _touch();
  }

  void setDriveFolder(String hangoutId, String? folderName) {
    final index = _hangouts.indexWhere((h) => h.id == hangoutId);
    if (index == -1) return;
    _hangouts[index] = _hangouts[index].copyWith(
      driveFolderName: folderName,
      clearDriveFolder: folderName == null,
    );
    _touch();
  }

  void toggleFollow(String attendeeId) {
    for (int i = 0; i < _hangouts.length; i++) {
      final updatedAttendees = _hangouts[i].attendees.map((a) {
        if (a.id == attendeeId) {
          return a.copyWith(isFollowing: !a.isFollowing);
        }
        return a;
      }).toList();

      _hangouts[i] = _hangouts[i].copyWith(attendees: updatedAttendees);
    }
    _touch();
  }

  void togglePhotoLike(String photoId) {
    for (final h in _hangouts) {
      for (final p in h.photos) {
        if (p.id == photoId) {
          p.isLiked = !p.isLiked;
        }
      }
    }
    _touch();
  }

  void savePhotoLocally(String photoId) {
    for (final h in _hangouts) {
      for (final p in h.photos) {
        if (p.id == photoId) {
          p.isSavedLocally = true;
        }
      }
    }
    _touch();
  }

  Future<PhotoItem> addPhotoWithFaceScan({
    required String hangoutId,
    required String imageUrl,
    int? originalSizeBytes,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Sign in to add photos');
    }

    _isScanning = true;
    notifyListeners();

    final hangout = _hangouts.firstWhere((h) => h.id == hangoutId);
    final faceBoxes = await FaceRecognitionService.instance.scanPhotoFaces(
      eventAttendees: hangout.attendees,
      photoSeed: '${imageUrl}_${DateTime.now().millisecondsSinceEpoch}',
      imagePath: imageUrl,
    );

    final detectedIds = faceBoxes.map((f) => f.attendeeId).toSet().toList();
    if (!detectedIds.contains(user.id)) {
      detectedIds.add(user.id);
    }

    final otherDetectedIds =
        detectedIds.where((id) => id != user.id).toList();
    final requiresConsent = otherDetectedIds.isNotEmpty;

    final rawBytes = originalSizeBytes ?? 4_500_000;
    // Int.clamp requires lo <= value <= hi; a tiny raw file (< 180 KB)
    // breaks that, so lower the floor to the file size.
    final rawInt = rawBytes.toInt();
    final floor = 180_000 < rawInt ? 180_000 : rawInt;
    final optimized = (rawInt * 0.04).round().clamp(floor, rawInt);

    final newPhoto = PhotoItem(
      id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
      hangoutId: hangoutId,
      imageUrl: imageUrl,
      uploaderName: user.name,
      uploaderAvatar: user.avatarUrl,
      detectedAttendeeIds: detectedIds,
      faceBoxes: faceBoxes,
      originalSizeBytes: rawBytes,
      optimizedSizeBytes: optimized,
      timestamp: DateTime.now(),
      approvalStatus: {
        for (final id in otherDetectedIds) id: ConsentDecision.pending,
      },
      isApprovedForPublicGallery: !requiresConsent,
      requiresConsent: requiresConsent,
    );

    final updatedPhotos = [newPhoto, ...hangout.photos];
    final index = _hangouts.indexWhere((h) => h.id == hangoutId);
    if (index != -1) {
      var updated = hangout.copyWith(photos: updatedPhotos);
      if (updated.heroImageUrl.isEmpty) {
        updated = updated.copyWith(heroImageUrl: imageUrl);
      }
      _hangouts[index] = updated;
    }

    _isScanning = false;
    _touch();
    return newPhoto;
  }

  Future<void> updateFaceProfile(String newAvatarUrl) async {
    await GoogleAuthService.instance.updateAvatar(newAvatarUrl);
    notifyListeners();
  }

  int get pendingConsentCount => pendingConsentPhotos.length;

  int get totalPhotosOfUser {
    final user = currentUser;
    if (user == null) return 0;

    int total = 0;
    for (final h in _hangouts) {
      total += h.photosCountForAttendee(user.id);
    }
    return total;
  }

  static String _todayLabel() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}';
  }

  static Color _accentForIndex(int index) {
    const accents = [
      Color(0xFFC7B8FB),
      Color(0xFFFDE68A),
      Color(0xFFA7F3D0),
      Color(0xFFBFDBFE),
      Color(0xFFFBCFE8),
    ];
    return accents[index % accents.length];
  }

  String _uniqueInviteCode() {
    final rng = Random();
    for (var attempt = 0; attempt < 50; attempt++) {
      final code = (1000 + rng.nextInt(9000)).toString();
      if (!_hangouts.any((h) => h.inviteCode == code)) return code;
    }
    return DateTime.now().millisecondsSinceEpoch.toString().substring(7);
  }
}
