import 'package:flutter/foundation.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// Result of trying to read an event pass from a physical NFC tag.
enum NfcTapResult { success, cancelled, unavailable, unsupported, error }

/// Thin wrapper around [NfcManager] for the Tap-to-Share event pass.
///
/// Two flows are supported:
///  * **Host**: write the event's invite URI onto a blank NTAG so guests can
///    tap their phone to join (see [writeEventUri]).
///  * **Guest**: hold the phone near a programmed tag to receive the URI and  ///    be routed into the event share (see [readEventUri]).
///
/// NFC only exists on Android/iOS hardware. Desktop and web report
/// [NfcAvailability.unsupported] instead of throwing, so the UI can degrade
/// gracefully.
class NfcService {
  NfcService._();
  static final NfcService instance = NfcService._();

  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Whether the device has NFC hardware and it is currently switched on.
  Future<NfcAvailability> checkAvailability() async {
    if (!isSupportedPlatform) return NfcAvailability.unsupported;
    try {
      return await NfcManager.instance.checkAvailability();
    } catch (_) {
      return NfcAvailability.unsupported;
    }
  }

  /// Starts a session and returns the invite URI stored on the first tag the
  /// user taps. Returns null when the tag carries no usable URI.
  ///
  /// [onResult] reports why the session ended so the UI can show accurate
  /// feedback instead of a silent no-op.
  Future<String?> readEventUri({
    String alertMessage = 'Hold your iPhone near the event pass',
    void Function(NfcTapResult result)? onResult,
  }) async {
    if (!isSupportedPlatform) {
      onResult?.call(NfcTapResult.unsupported);
      return null;
    }

    final availability = await checkAvailability();
    if (availability != NfcAvailability.enabled) {
      onResult?.call(NfcTapResult.unavailable);
      return null;
    }

    String? uri;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        alertMessageIos: alertMessage,
        onDiscovered: (tag) async {
          uri = await _readUriFromTag(tag);
          // End the session as soon as we have what we came for.
          await NfcManager.instance.stopSession();
        },
      );
    } catch (_) {
      onResult?.call(NfcTapResult.error);
      return null;
    }

    onResult?.call(uri == null ? NfcTapResult.cancelled : NfcTapResult.success);
    return uri;
  }

  /// Writes [uri] as an NDEF URI record onto the first tag the user taps.
  /// Returns true when the tag was written successfully.
  Future<bool> writeEventUri(
    String uri, {
    String alertMessage = 'Hold your iPhone near a blank tag',
    void Function(NfcTapResult result)? onResult,
  }) async {
    if (!isSupportedPlatform) {
      onResult?.call(NfcTapResult.unsupported);
      return false;
    }

    final availability = await checkAvailability();
    if (availability != NfcAvailability.enabled) {
      onResult?.call(NfcTapResult.unavailable);
      return false;
    }

    var written = false;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        alertMessageIos: alertMessage,
        onDiscovered: (tag) async {
          written = await _writeUriToTag(tag, uri);
          await NfcManager.instance.stopSession();
        },
      );
    } catch (_) {
      onResult?.call(NfcTapResult.error);
      return false;
    }

    onResult?.call(written ? NfcTapResult.success : NfcTapResult.error);
    return written;
  }

  Future<String?> _readUriFromTag(NfcTag tag) async {
    final message =
        NdefAndroid.from(tag)?.cachedNdefMessage ??
        await NdefAndroid.from(tag)?.getNdefMessage() ??
        NdefIos.from(tag)?.cachedNdefMessage ??
        await NdefIos.from(tag)?.readNdef();

    if (message == null) return null;
    for (final record in message.records) {
      final uri = decodeUriRecord(record.type, record.payload);
      if (uri != null) return uri;
    }
    return null;
  }

  Future<bool> _writeUriToTag(NfcTag tag, String uri) async {
    final message = NdefMessage(records: [buildUriRecord(uri)]);
    final android = NdefAndroid.from(tag);
    if (android != null) {
      await android.writeNdefMessage(message);
      return true;
    }
    final ios = NdefIos.from(tag);
    if (ios != null) {
      await ios.writeNdef(message);
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // NDEF URI record codec — pure functions, unit-testable without hardware.
  // Spec: NFC Forum URI Record Type Definition.
  // ---------------------------------------------------------------------------

  static const List<String> _uriPrefixes = [
    '', // 0x00
    'http://www.', // 0x01
    'https://www.', // 0x02
    'http://', // 0x03
    'https://', // 0x04
    'tel:', // 0x05
    'mailto:', // 0x06
    'ftp://anonymous:anonymous@', // 0x07
    'ftp://ftp.', // 0x08
    'ftps://', // 0x09
    'sftp://', // 0x0A
    'smb://', // 0x0B
    'nfs://', // 0x0C
    'ftp://', // 0x0D
    'dav://', // 0x0E
    'news:', // 0x0F
    'telnet://', // 0x10
    'imap:', // 0x11
    'rtsp://', // 0x12
    'urn:', // 0x13
    'pop:', // 0x14
    'sip:', // 0x15
    'sips:', // 0x16
    'tftp:', // 0x17
    'btspp://', // 0x18
    'btl2cap://', // 0x19
    'btgoep://', // 0x1A
    'tcpobex://', // 0x1B
    'irdaobex://', // 0x1C
    'file://', // 0x1D
    'urn:epc:id:', // 0x1E
    'urn:epc:tag:', // 0x1F
    'urn:epc:pat:', // 0x20
    'urn:epc:raw:', // 0x21
    'urn:epc:', // 0x22
    'urn:nfc:', // 0x23
  ];

  /// Builds a well-known NDEF URI record ("U") for [uri].
  static NdefRecord buildUriRecord(String uri) {
    var prefixCode = 0;
    var remainder = uri;
    // Longest match wins so `https://www.` is preferred over `https://`.
    for (var i = _uriPrefixes.length - 1; i > 0; i--) {
      final prefix = _uriPrefixes[i];
      if (prefix.isNotEmpty && uri.startsWith(prefix)) {
        prefixCode = i;
        remainder = uri.substring(prefix.length);
        break;
      }
    }

    final payload = Uint8List.fromList([
      prefixCode,
      ...remainder.codeUnits,
    ]);

    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]), // 'U'
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Decodes an NDEF record into a URI, or null when it isn't a URI record.
  static String? decodeUriRecord(Uint8List type, Uint8List payload) {
    if (type.length != 1 || type.first != 0x55) return null;
    if (payload.isEmpty) return null;

    final prefixCode = payload.first;
    if (prefixCode >= _uriPrefixes.length) return null;

    final rest = String.fromCharCodes(payload.sublist(1));
    return '${_uriPrefixes[prefixCode]}$rest';
  }
}
