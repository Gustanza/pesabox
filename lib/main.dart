import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'i18n/i18n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18n.load(); // saved language (Swahili by default)

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const PesaBoxApp());
}

class PesaBoxApp extends StatelessWidget {
  const PesaBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilding on a language change recreates the app from the splash
    // screen, so every screen picks up the new language.
    return ValueListenableBuilder<String>(
      valueListenable: I18n.locale,
      builder: (context, code, _) => MaterialApp(
        key: ValueKey(code),
        title: 'PesaBox',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: Locale(code),
        supportedLocales: const [Locale('sw'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
