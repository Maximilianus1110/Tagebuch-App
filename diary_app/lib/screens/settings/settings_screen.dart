import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diary_app/services/theme_provider.dart';
import 'package:diary_app/services/export_service.dart';
import 'package:diary_app/services/settings_service.dart';
import 'package:diary_app/services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _restTimerSeconds = 150;
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final seconds = await _settingsService.getRestTimerDuration();
    if (mounted) {
      setState(() {
        _restTimerSeconds = seconds;
      });
    }
  }

  Future<void> _updateRestTimer(int deltaSeconds) async {
    final newValue = _restTimerSeconds + deltaSeconds;
    if (newValue >= 0) {
      setState(() {
        _restTimerSeconds = newValue;
      });
      await _settingsService.setRestTimerDuration(newValue);
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

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
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Gym', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            title: const Text('Pausen-Timer'),
            subtitle: const Text('Dauer der Pause zwischen Sätzen'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _updateRestTimer(-10),
                ),
                Text(
                  _formatDuration(_restTimerSeconds),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _updateRestTimer(10),
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
            title: const Text('Daten exportieren'),
            subtitle: const Text('Textbasierter Export (Tagebuch & Gym)'),
            onTap: () async {
              await ExportService.exportAllData(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Backup erstellen'),
            subtitle: const Text('Vollständiges Backup (Tagebuch, Gym, Küche, etc.)'),
            onTap: _showCreateBackupDialog,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Backup wiederherstellen'),
            subtitle: const Text('Daten aus einer ZIP-Datei laden'),
            onTap: _showRestoreBackupDialog,
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

  void _showCreateBackupDialog() {
    bool includeDiary = true;
    bool includeGym = true;
    bool includeKitchen = true;
    bool includeRecipes = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Backup erstellen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Wähle die Kategorien aus, die gesichert werden sollen:'),
                  CheckboxListTile(
                    title: const Text('Tagebuch'),
                    value: includeDiary,
                    onChanged: (val) => setState(() => includeDiary = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Gym (Pläne, Verlauf etc.)'),
                    value: includeGym,
                    onChanged: (val) => setState(() => includeGym = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Küche (Produkte, Bestand, Historie)'),
                    value: includeKitchen,
                    onChanged: (val) => setState(() => includeKitchen = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Rezepte'),
                    value: includeRecipes,
                    onChanged: (val) => setState(() => includeRecipes = val ?? true),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    final backupService = BackupService();
                    await backupService.createBackup(
                      includeDiary: includeDiary,
                      includeGym: includeGym,
                      includeKitchen: includeKitchen,
                      includeRecipes: includeRecipes,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup erfolgreich erstellt!')),
                      );
                    }
                  },
                  child: const Text('Erstellen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRestoreBackupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backup wiederherstellen'),
          content: const Text(
            'Achtung: Dies überschreibt deine aktuellen Daten für alle im Backup enthaltenen Kategorien.\n\n'
            'Bist du sicher, dass du fortfahren möchtest?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                // Show a loading dialog since it can take a few seconds
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                final backupService = BackupService();
                final success = await backupService.restoreBackup();

                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup erfolgreich wiederhergestellt! Bitte App neu starten.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fehler bei der Wiederherstellung oder Vorgang abgebrochen.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Wiederherstellen'),
            ),
          ],
        );
      },
    );
  }
}
