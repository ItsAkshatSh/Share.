import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../models/hangout.dart';
import '../services/hangout_repository.dart';
import '../services/nfc_service.dart';

class TapToShareModal extends StatefulWidget {
  final Hangout hangout;

  const TapToShareModal({super.key, required this.hangout});

  @override
  State<TapToShareModal> createState() => _TapToShareModalState();
}

class _TapToShareModalState extends State<TapToShareModal> {
  bool _nfcBusy = false;
  String? _nfcStatus;

  String get _inviteUri => HangoutRepository.instance.inviteUriFor(widget.hangout);

  // ---------------------------------------------------------------------------
  // NFC — host writes the invite onto a blank tag, guest taps to join.
  // ---------------------------------------------------------------------------

  Future<void> _writeTag() async {
    setState(() {
      _nfcBusy = true;
      _nfcStatus = 'Hold your phone near a blank NFC tag…';
    });

    await NfcService.instance.writeEventUri(
      _inviteUri,
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _nfcBusy = false;
          _nfcStatus = switch (result) {
            NfcTapResult.success => 'Tag programmed! Guests can now tap to join.',
            NfcTapResult.cancelled => 'No tag detected — try again.',
            NfcTapResult.unavailable => 'NFC is turned off on this device.',
            NfcTapResult.unsupported => 'This device has no NFC reader.',
            NfcTapResult.error => 'Could not write to that tag.',
          };
        });
      },
    );
  }

  Future<void> _tapToJoin() async {
    setState(() {
      _nfcBusy = true;
      _nfcStatus = 'Hold your phone near the event pass…';
    });

    NfcTapResult? outcome;
    final uri = await NfcService.instance.readEventUri(
      onResult: (result) => outcome = result,
    );
    if (!mounted) return;

    // Route the tapped URI into the matching event share.
    final joined = uri == null
        ? null
        : HangoutRepository.instance.joinEventByCode(uri);

    setState(() {
      _nfcBusy = false;
      if (joined != null) {
        _nfcStatus = 'Joined "${joined.title.replaceAll('\n', ' ')}" — you are in!';
      } else {
        _nfcStatus = switch (outcome) {
          NfcTapResult.cancelled => 'No pass detected — try again.',
          NfcTapResult.unavailable => 'NFC is turned off on this device.',
          NfcTapResult.unsupported => 'This device has no NFC reader.',
          NfcTapResult.error => 'That tag was not readable.',
          _ => 'That pass does not match any event share.',
        };
      }
    });

    if (joined != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceRaised,
          content: Text(
            'Joined ${joined.title.replaceAll('\n', ' ')} via NFC tap.',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _inviteUri));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.jetBlack,
        content: Text(
          'Invite link copied: $_inviteUri',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // iOS grabber
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Tap-to-Share Pass',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.confirmation_number_outlined,
                              size: 18, color: AppColors.textPrimary),
                        ],
                      ),
                      Text(
                        'Instant Event Join & Face Routing',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.activeGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                  icon: Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Apple Wallet style pass with a real, scannable QR code
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.jetBlack,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.jetBlack.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hangout.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neonLime,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.hangout.title.replaceAll('\n', ' '),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.surfaceWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.nfc,
                        color: AppColors.neonLime,
                        size: 24,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Real QR code encoding the invite deep link
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Semantics(
                          label:
                              'QR code to join ${widget.hangout.title.replaceAll('\n', ' ')}',
                          child: QrImageView(
                            data: _inviteUri,
                            size: 180,
                            version: QrVersions.auto,
                            backgroundColor: AppColors.surfaceWhite,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.jetBlack,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.jetBlack,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'PASS PIN: ${widget.hangout.inviteCode}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: AppColors.jetBlack,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    _inviteUri,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.surfaceWhite.withValues(alpha: 0.6),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live NFC session status (only shown while interacting)
            AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.fast),
              child: _nfcStatus == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(_nfcStatus),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          if (_nfcBusy)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.jetBlack,
                              ),
                            )
                          else
                            Icon(
                              Icons.nfc,
                              size: 16,
                              color: AppColors.jetBlack,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _nfcStatus!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Guest action: tap a physical pass to join
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _nfcBusy ? null : _tapToJoin,
                icon: const Icon(Icons.contactless, size: 18),
                label: const Text(
                  'Tap Phone to Join Share',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jetBlack,
                  foregroundColor: AppColors.onDarkChrome,
                  disabledBackgroundColor: AppColors.surfaceMuted,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Host action: program a blank tag + copy the link
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _nfcBusy ? null : _writeTag,
                    icon: const Icon(Icons.nfc, size: 16),
                    label: const Text(
                      'Program Tag',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.jetBlack,
                      side: BorderSide(color: AppColors.divider, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text(
                      'Copy Link',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonLime,
                      foregroundColor: AppColors.jetBlack,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
