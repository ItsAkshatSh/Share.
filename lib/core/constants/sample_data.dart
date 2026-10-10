import 'package:flutter/material.dart';
import '../../models/attendee.dart';
import '../../models/hangout.dart';
import '../../models/photo_item.dart';
import '../../services/face_recognition_service.dart';

class SampleData {
  SampleData._();

  static final FaceRecognitionService _faceService =
      FaceRecognitionService.instance;

  // Current logged in user via Google Sign-In
  static final Attendee currentUser = Attendee(
    id: 'user_jannes',
    name: 'Jannes Miller',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
    subtitle: 'Google Account • jannes@gmail.com',
    followersCount: '2.4K',
    faceVector: _faceService.generateSimulatedVector('jannes_vector'),
    isCurrentUser: true,
  );

  // Attendees from the collaborative social shares
  static final Attendee wadeWarren = Attendee(
    id: 'user_wade',
    name: 'Wade Warren',
    avatarUrl:
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
    subtitle: 'Host & Co-Organizer',
    followersCount: '3.1K',
    faceVector: _faceService.generateSimulatedVector('wade_vector'),
    isFollowing: true,
  );

  static final Attendee sarahChen = Attendee(
    id: 'user_sarah',
    name: 'Sarah Chen',
    avatarUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80',
    subtitle: 'Brooklyn, NY',
    followersCount: '1.756K',
    faceVector: _faceService.generateSimulatedVector('sarah_vector'),
    isFollowing: true,
  );

  static final Attendee alexRivera = Attendee(
    id: 'user_alex',
    name: 'Alex Rivera',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
    subtitle: 'Event Photographer',
    followersCount: '4.8K',
    faceVector: _faceService.generateSimulatedVector('alex_vector'),
    isFollowing: true,
  );

  static final Attendee savannahNguyen = Attendee(
    id: 'user_savannah',
    name: 'Savannah Nguyen',
    avatarUrl:
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=300&q=80',
    subtitle: 'Creative Director',
    followersCount: '1.156K',
    faceVector: _faceService.generateSimulatedVector('savannah_vector'),
  );

  static final Attendee brooklynSimmons = Attendee(
    id: 'user_brooklyn',
    name: 'Brooklyn Simmons',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
    subtitle: 'Designer',
    followersCount: '4.2K',
    faceVector: _faceService.generateSimulatedVector('brooklyn_vector'),
  );

  // Sample Photos for Neon Rooftop Hangout
  static List<PhotoItem> getRooftopPhotos() {
    return [
      // Photo 1: Publicly approved group shot
      PhotoItem(
        id: 'photo_rooftop_1',
        hangoutId: 'event_rooftop',
        imageUrl:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=1200&q=80',
        uploaderName: 'Wade Warren',
        uploaderAvatar:
            'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
        detectedAttendeeIds: ['user_jannes', 'user_wade', 'user_sarah'],
        faceBoxes: const [
          DetectedFaceBox(
            attendeeId: 'user_jannes',
            attendeeName: 'You (Jannes)',
            x: 0.22,
            y: 0.35,
            width: 0.22,
            height: 0.28,
            confidence: 0.98,
          ),
          DetectedFaceBox(
            attendeeId: 'user_wade',
            attendeeName: 'Wade Warren',
            x: 0.55,
            y: 0.32,
            width: 0.22,
            height: 0.28,
            confidence: 0.95,
          ),
        ],
        originalSizeBytes: 11200000,
        optimizedSizeBytes: 280000,
        isApprovedForPublicGallery: true,
      ),

      // Photo 2: Pending in user's Consent Vault (taken by Alex, waiting for Jannes's approval!)
      PhotoItem(
        id: 'photo_consent_pending_1',
        hangoutId: 'event_rooftop',
        imageUrl:
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
        uploaderName: 'Alex Rivera',
        uploaderAvatar:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
        detectedAttendeeIds: ['user_jannes', 'user_alex'],
        faceBoxes: const [
          DetectedFaceBox(
            attendeeId: 'user_jannes',
            attendeeName: 'You (Jannes)',
            x: 0.35,
            y: 0.28,
            width: 0.24,
            height: 0.26,
            confidence: 0.97,
          ),
        ],
        originalSizeBytes: 8900000,
        optimizedSizeBytes: 215000,
        approvalStatus: const {
          'user_jannes': ConsentDecision.pending,
        },
        isApprovedForPublicGallery: false,
        requiresConsent: true,
      ),

      // Photo 3: Candid laughing moment (also in Consent Vault)
      PhotoItem(
        id: 'photo_consent_pending_2',
        hangoutId: 'event_rooftop',
        imageUrl:
            'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=1200&q=80',
        uploaderName: 'Wade Warren',
        uploaderAvatar:
            'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
        detectedAttendeeIds: ['user_jannes', 'user_sarah'],
        faceBoxes: const [
          DetectedFaceBox(
            attendeeId: 'user_jannes',
            attendeeName: 'You (Jannes)',
            x: 0.40,
            y: 0.25,
            width: 0.20,
            height: 0.25,
            confidence: 0.99,
          ),
        ],
        originalSizeBytes: 12500000,
        optimizedSizeBytes: 310000,
        approvalStatus: const {
          'user_jannes': ConsentDecision.pending,
        },
        isApprovedForPublicGallery: false,
        requiresConsent: true,
      ),

      // Photo 4: Golden hour terrace
      PhotoItem(
        id: 'photo_rooftop_4',
        hangoutId: 'event_rooftop',
        imageUrl:
            'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=80',
        uploaderName: 'Sarah Chen',
        uploaderAvatar:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80',
        detectedAttendeeIds: ['user_sarah', 'user_savannah'],
        faceBoxes: const [
          DetectedFaceBox(
            attendeeId: 'user_sarah',
            attendeeName: 'Sarah Chen',
            x: 0.30,
            y: 0.30,
            width: 0.22,
            height: 0.25,
            confidence: 0.94,
          ),
        ],
        originalSizeBytes: 7800000,
        optimizedSizeBytes: 198000,
        isApprovedForPublicGallery: true,
      ),

      // Photo 5: DJ booth & dancing
      PhotoItem(
        id: 'photo_rooftop_5',
        hangoutId: 'event_rooftop',
        imageUrl:
            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=1200&q=80',
        uploaderName: 'Jannes Miller',
        uploaderAvatar:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
        detectedAttendeeIds: ['user_jannes', 'user_wade'],
        faceBoxes: const [
          DetectedFaceBox(
            attendeeId: 'user_jannes',
            attendeeName: 'You (Jannes)',
            x: 0.18,
            y: 0.30,
            width: 0.22,
            height: 0.26,
            confidence: 0.99,
          ),
        ],
        originalSizeBytes: 10100000,
        optimizedSizeBytes: 250000,
        isApprovedForPublicGallery: true,
      ),
    ];
  }

  // Sample Collaborative Events
  static List<Hangout> getSampleEvents() {
    final rooftopPhotos = getRooftopPhotos();
    final allAttendees = [
      currentUser,
      wadeWarren,
      sarahChen,
      alexRivera,
      savannahNguyen,
      brooklynSimmons,
    ];

    return [
      Hangout(
        id: 'event_rooftop',
        title: 'Neon Rooftop\nHangout',
        category: 'Rooftop Party',
        location: 'Skyline Terrace, Brooklyn NY',
        dateDescription: 'Saturday, 9PM',
        heroImageUrl:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=1200&q=80',
        inviteCode: '8492',
        description:
            'Collaborative live photo share for the Brooklyn Skyline Rooftop hangout. All photos auto-routed to detected attendees with Ghost Mode consent privacy.',
        ttlDaysRemaining: 14,
        accentColor: const Color(0xFFC7B8FB),
        latitude: 40.70,
        longitude: -73.96,
        driveFolderName: 'AutoShare/Neon Rooftop Hangout',
        hostId: 'user_wade',
        attendees: allAttendees,
        photos: rooftopPhotos,
      ),
      Hangout(
        id: 'event_birthday',
        title: 'Sarah\'s 24th\nBirthday Bash',
        category: 'Birthday Party',
        location: 'SoHo Loft, New York',
        dateDescription: 'Friday, 8PM',
        heroImageUrl:
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
        inviteCode: '5913',
        description:
            'Dump all your birthday party photos here! On-device face detection organizes every candid angle for Sarah and the crew.',
        ttlDaysRemaining: 11,
        accentColor: const Color(0xFFFDE68A),
        latitude: 40.72,
        longitude: -74.00,
        hostId: 'user_sarah',
        attendees: [
          currentUser,
          sarahChen,
          wadeWarren,
          savannahNguyen,
        ],
        photos: rooftopPhotos.sublist(1, 4),
      ),
      Hangout(
        id: 'event_lakehouse',
        title: 'Lake House\nSummer Trip',
        category: 'Weekend Getaway',
        location: 'Lake Tahoe, CA',
        dateDescription: 'Fri - Sun',
        heroImageUrl:
            'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=80',
        inviteCode: '2377',
        description:
            'Weekend getaway share. Full-resolution originals sync directly over local Wi-Fi at the cabin, then WebP versions back up to the free cloud tier.',
        ttlDaysRemaining: 14,
        accentColor: const Color(0xFFA7F3D0),
        latitude: 39.09,
        longitude: -120.04,
        hostId: 'user_jannes',
        attendees: [
          currentUser,
          alexRivera,
          brooklynSimmons,
          savannahNguyen,
        ],
        photos: rooftopPhotos.sublist(0, 2),
      ),
    ];
  }
}
