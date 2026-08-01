import 'package:flutter/material.dart';
import 'package:diary_app/screens/diary_screen.dart';
import 'package:diary_app/screens/gym_screen.dart';
import 'package:diary_app/screens/kitchen/kitchen_screen.dart';
import 'package:diary_app/screens/kitchen/recipes_screen.dart';
import 'package:diary_app/screens/settings/settings_screen.dart';
import 'package:diary_app/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(title: 'Hauptmenü'),
      appBar: AppBar(
        title: const Text('Tagebuch App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Willkommen zurück! 👋',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Wähle einen Bereich aus, um zu starten:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                  childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2.2 : 2.0,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildFeatureCard(
                      context,
                      title: 'Gym',
                      subtitle: 'Fitness-Tracking, Trainingspläne & Statistiken',
                      icon: Icons.fitness_center,
                      gradientColors: [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const GymScreen()),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Tagebuch',
                      subtitle: 'Chronologische Notizen, Kalender & Papierkorb',
                      icon: Icons.book,
                      gradientColors: [const Color(0xFF00B4D8), const Color(0xFF0077B6)],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const DiaryScreen()),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Küche & Vorrat',
                      subtitle: 'Vorräte verwalten, MHD-Ampel & JSON-Import',
                      icon: Icons.kitchen,
                      gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const KitchenScreen()),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Rezepte',
                      subtitle: 'Rezepte verwalten, Kochbarkeit & Bestandsabzug',
                      icon: Icons.restaurant_menu,
                      gradientColors: [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const RecipesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
