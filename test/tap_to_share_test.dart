import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/core/constants/sample_data.dart';
import 'package:share/screens/tap_to_share_modal.dart';

void main() {
  testWidgets('Tap-to-Share renders a real QR code and the invite link',
      (tester) async {
    final hangout = SampleData.getSampleEvents().first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TapToShareModal(hangout: hangout)),
      ),
    );
    await tester.pump();

    // A genuine QrImageView is present (not a hand-drawn placeholder grid).
    expect(find.byType(QrImageView), findsOneWidget);

    // It is laid out at a real, scannable size.
    final qrSize = tester.getSize(find.byType(QrImageView));
    expect(qrSize.width, greaterThanOrEqualTo(150));
    expect(qrSize.height, greaterThanOrEqualTo(150));

    // The pass shows the deep link a guest's camera would resolve.
    expect(
      find.text('https://autoshare.app/share/${hangout.inviteCode}'),
      findsOneWidget,
    );

    // The PIN and the NFC join action are surfaced to the user.
    expect(find.textContaining('PASS PIN: ${hangout.inviteCode}'), findsOneWidget);
    expect(find.text('Tap Phone to Join Share'), findsOneWidget);
    expect(find.text('Program Tag'), findsOneWidget);
  });
}
