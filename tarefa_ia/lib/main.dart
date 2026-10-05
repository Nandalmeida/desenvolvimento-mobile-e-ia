import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() => runApp(const TarefaIaApp());

class TarefaIaApp extends StatelessWidget {
  const TarefaIaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TarefaIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
