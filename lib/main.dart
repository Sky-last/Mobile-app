import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notes_app_5sia1/auth/login_screen.dart';
import 'package:notes_app_5sia1/providers/theme_provider.dart';
import 'package:notes_app_5sia1/services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(
    ChangeNotifierProvider(create: (_) => ThemeProvider(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Notes App',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const LoginScreen(),
        );
      },
    );
  }
}
