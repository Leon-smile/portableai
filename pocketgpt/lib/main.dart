import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/chat_page.dart';

void main() {
  runApp(const ProviderScope(child: PocketGptApp()));
}

class PocketGptApp extends StatelessWidget {
  const PocketGptApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3B6EF5);
    return MaterialApp(
      title: 'PocketGPT',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const ChatPage(),
    );
  }
}
