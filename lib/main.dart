import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_settings.dart';
import 'services/preferences_service.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefsService = await PreferencesService.create();
  final settings = AppSettings();
  prefsService.loadInto(settings);

  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: RollingTextApp(prefsService: prefsService),
    ),
  );
}

class RollingTextApp extends StatelessWidget {
  final PreferencesService prefsService;

  const RollingTextApp({super.key, required this.prefsService});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      title: 'Rolling Text',
      theme: themeDataFor(settings.theme),
      home: MainScreen(prefsService: prefsService),
      debugShowCheckedModeBanner: false,
    );
  }
}
