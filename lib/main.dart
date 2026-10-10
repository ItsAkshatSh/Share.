import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/theme_controller.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/google_auth_service.dart';
import 'services/hangout_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore persisted state before the first frame.
  await ThemeController.instance.load();
  await GoogleAuthService.instance.load();
  await HangoutRepository.instance.load();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  _applyChrome();

  // Signed-out first launch → the full-screen login page. Signed-in (or
  // returning) launches go straight to the home feed.
  final Widget first = GoogleAuthService.instance.isSignedIn
      ? const HomeScreen()
      : const LoginScreen();

  runApp(AutoPhotoShareApp(home: first));
}

void _applyChrome() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
}

class AutoPhotoShareApp extends StatelessWidget {
  final Widget home;

  const AutoPhotoShareApp({
    super.key,
    required this.home,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        _applyChrome();

        return MaterialApp(
          title: 'Share — Auto Photo Share',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'JetBrainsMono',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accent,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
          ),
          home: home,
        );
      },
    );
  }
}
