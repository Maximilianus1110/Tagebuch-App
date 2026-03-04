import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diary_app/services/theme_provider.dart';
import 'package:diary_app/services/export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Darstellung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_getThemeName(themeProvider.themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  themeProvider.setThemeMode(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Hell'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dunkel'),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Daten', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Alle Daten exportieren'),
            subtitle: const Text('Tagebuch & Gym Daten'),
            onTap: () async {
              await ExportService.exportAllData(context);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Über', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Hell';
      case ThemeMode.dark:
        return 'Dunkel';
    }
  }
}
