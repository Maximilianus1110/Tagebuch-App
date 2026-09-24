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
    final isWide = MediaQuery.of(context).size.width > 600;

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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Willkommen zurück! 👋',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),

              const SizedBox(height: 10),
              
              Expanded(
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWide ? 2 : 1,
                  childAspectRatio: isWide ? 2.0 : 2.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _buildFeatureCard(
                      context,
                      title: 'Gym',
                      subtitle: 'Fitness-Tracking, Pläne & Statistiken',
                      icon: Icons.fitness_center,
                      accentColor: const Color(0xFF6366F1),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const GymScreen()),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Tagebuch',
                      subtitle: 'Chronologische Notizen & Kalender',
                      icon: Icons.book,
                      accentColor: const Color(0xFF00B4D8),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const DiaryScreen()),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Küche & Vorrat',
                      subtitle: 'Bestandsverwaltung & MHD-Ampel',
                      icon: Icons.kitchen,
                      accentColor: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const KitchenScreen()),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Rezepte',
                      subtitle: 'Rezeptverwaltung & Bestandsabzug',
                      icon: Icons.restaurant_menu,
                      accentColor: const Color(0xFFF59E0B),
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
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

