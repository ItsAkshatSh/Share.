import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendee.dart';
import 'face_recognition_service.dart';
import 'hangout_codec.dart';

class GoogleAuthService extends ChangeNotifier {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  /// Google OAuth **web client id** for this project.
  ///
  /// Android's Credential-Manager flow needs it because this app's
  /// google-services.json currently has no `oauth_client` entry of
  /// type 3 (web). To enable the real Google button:
  ///
  ///   1. Firebase console → Authentication → Sign-in method → Google.
  ///   2. Copy the **Web client ID** (…apps.googleusercontent.com).
  ///   3. Paste it here and re-download google-services.json if prompted.
  ///
  /// Left empty by default; when empty the app falls back to the manual
  /// profile form instead of failing at runtime.
  static const String webClientId = '439742232683-uo05ev1h5huc6mnbf79i4no30og0mdol.apps.googleusercontent.com';

  /// Whether a real Google OAuth flow can run on this platform.
  /// On Web/Desktop, sign-in gracefully falls back to the manual profile sheet.
  /// On Android/iOS, real Google OAuth is triggered via google_sign_in.
  bool get canSignInReal {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Last sign-in failure so callers (the profile sheet) can surface
  /// an inline message instead of failing silently.
  String? lastError;

  static const _userKey = 'signed_in_user_v1';

  Attendee? _currentUser;
  bool get isSignedIn => _currentUser != null;
  Attendee? get currentUser => _currentUser;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userKey);
      if (raw != null) {
        final user = HangoutCodec.decodeUser(raw);
        if (user != null) {
          _currentUser = HangoutCodec.ensureFaceVector(
            user.copyWith(isCurrentUser: true),
          );
        }
      }
    } catch (_) {
      // Tests / missing platform — stay signed out.
    }
    notifyListeners();
  }

  Future<void> _persistUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _currentUser;
      if (user == null) {
        await prefs.remove(_userKey);
      } else {
        await prefs.setString(_userKey, HangoutCodec.encodeUser(user));
      }
    } catch (_) {}
  }

  static String avatarUrlForName(String name) {
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name.trim())}&size=300&background=FB7A1E&color=160D00';
  }

  /// Real Google OAuth sign-in. Returns the signed-in [Attendee], or null
  /// when the platform can't run the flow (web/desktop) — in which case the
  /// caller should show the manual profile form.
  ///
  /// Uses the plugin's 7.x contract:
  ///   GoogleSignIn.instance.initialize(serverClientId: ...) once,
  ///   then authenticate() inside a user interaction.
  Future<Attendee?> signIn() async {
    if (!canSignInReal) return null;
    try {
      lastError = null;
      final gs = GoogleSignIn.instance;
      await gs.initialize(
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );
      final account = await gs.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      return _attachUser(
        id: 'google_${account.id}',
        name: account.displayName ?? account.email.split('@').first,
        email: account.email,
        avatarUrl: account.photoUrl ?? avatarUrlForName(account.displayName ?? ''),
      );
    } on GoogleSignInException catch (e) {
      lastError = switch (e.code) {
        GoogleSignInExceptionCode.clientConfigurationError =>
          'Google sign-in is not configured for this build — '
              'add a Web client ID to GoogleAuthService.webClientId.',
        GoogleSignInExceptionCode.canceled => null,
        _ => e.toString().split('\n').first,
      };
      debugPrint('Google sign-in failed: $e');
      return null;
    } on Exception catch (e) {
      lastError = e.toString().split('\n').first;
      debugPrint('Google sign-in failed: $e');
      return null;
    }
  }

  /// Manual profile sign-in (used on web/desktop and as a fallback).
  /// Returns false when validation failed so the sheet can show why.
  Future<bool> signInWithProfile({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    if (trimmedName.isEmpty || trimmedEmail.isEmpty) {
      return false;
    }

    final id = 'user_${trimmedEmail.hashCode.abs()}';
    final photo = avatarUrl ?? avatarUrlForName(trimmedName);
    final faceVec =
        FaceRecognitionService.instance.generateSimulatedVector(photo);

    _currentUser = Attendee(
      id: id,
      name: trimmedName,
      avatarUrl: photo,
      subtitle: trimmedEmail,
      followersCount: '',
      faceVector: faceVec,
      isCurrentUser: true,
    );
    lastError = null;
    await _persistUser();
    notifyListeners();
    return true;
  }

  /// Attach a Google-signed-in user to the local model and persist.
  Attendee? _attachUser({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
  }) {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    if (trimmedName.isEmpty && trimmedEmail.isEmpty) return null;

    final photo = avatarUrl ?? avatarUrlForName(trimmedName);
    final faceVec =
        FaceRecognitionService.instance.generateSimulatedVector(photo);

    _currentUser = Attendee(
      id: id,
      name: trimmedName.isEmpty ? trimmedEmail.split('@').first : trimmedName,
      avatarUrl: photo,
      subtitle: trimmedEmail.isNotEmpty ? trimmedEmail : trimmedName,
      followersCount: '',
      faceVector: faceVec,
      isCurrentUser: true,
    );
    unawaited(_persistUser());
    notifyListeners();
    return _currentUser;
  }

  Future<void> signOut() async {
    _currentUser = null;
    if (canSignInReal) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _persistUser();
    notifyListeners();
  }

  Future<void> updateAvatar(String newAvatarUrl) async {
    final user = _currentUser;
    if (user == null || newAvatarUrl.isEmpty) return;

    _currentUser = user.copyWith(
      avatarUrl: newAvatarUrl,
      faceVector:
          FaceRecognitionService.instance.generateSimulatedVector(newAvatarUrl),
    );
    await _persistUser();
    notifyListeners();
  }

  /// Used by tests only — seeds a known profile without persistence noise.
  /// The IDs match [SampleData] so consent-vault tests can find the current
  /// user in the sample photos' [detectedAttendeeIds].
  @visibleForTesting
  Future<void> switchDemoAccount(int index) async {
    const demoUsers = [
      (
        'user_jannes',
        'Jannes Miller',
        'jannes@gmail.com',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80'
      ),
      (
        'user_sarah',
        'Sarah Chen',
        'sarah.chen@gmail.com',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80'
      ),
      (
        'user_alex',
        'Alex Rivera',
        'alex.rivera@gmail.com',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80'
      ),
    ];

    final demo = demoUsers[index % demoUsers.length];
    _currentUser = Attendee(
      id: demo.$1,
      name: demo.$2,
      avatarUrl: demo.$4,
      subtitle: demo.$3,
      followersCount: '',
      faceVector:
          FaceRecognitionService.instance.generateSimulatedVector(demo.$4),
      isCurrentUser: true,
    );
    await _persistUser();
    notifyListeners();
  }
}
