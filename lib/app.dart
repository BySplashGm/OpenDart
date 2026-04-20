import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

class OpenDartApp extends StatelessWidget {
  const OpenDartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenDart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
