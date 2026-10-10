import 'package:shared_preferences/shared_preferences.dart';

import '../models/hangout.dart';
import 'hangout_codec.dart';

class HangoutStore {
  HangoutStore._();

  static const _hangoutsKey = 'hangouts_state_v1';

  static Future<({List<Hangout> hangouts, String selectedHangoutId})?>
      load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_hangoutsKey);
      if (raw == null || raw.isEmpty) return null;
      return HangoutCodec.decodeState(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required List<Hangout> hangouts,
    required String selectedHangoutId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _hangoutsKey,
        HangoutCodec.encodeState(
          hangouts: hangouts,
          selectedHangoutId: selectedHangoutId,
        ),
      );
    } catch (_) {
      // Best-effort persistence (tests may lack platform channels).
    }
  }
}
