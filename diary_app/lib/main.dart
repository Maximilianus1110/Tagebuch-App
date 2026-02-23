import 'package:flutter/material.dart';
import 'package:diary_app/screens/home_screen.dart';
import 'package:diary_app/services/export_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tagebuch App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(
        onExport: (context) async {
          await ExportService.exportEntries();
        },
      ),
    );
  }
}
