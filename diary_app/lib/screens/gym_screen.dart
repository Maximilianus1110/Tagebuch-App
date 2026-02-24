import 'package:flutter/material.dart';
import 'package:diary_app/screens/diary_screen.dart';

class GymScreen extends StatelessWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'diary') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const DiaryScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'diary',
                  child: Row(
                    children: [
                      Icon(Icons.book, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Modus wechseln'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Demnächst verfügbar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
