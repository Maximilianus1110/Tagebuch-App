import 'package:flutter/material.dart';
import 'package:diary_app/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  int _currentDuration = 150;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final duration = await _settingsService.getRestTimerDuration();
    if (mounted) {
      setState(() {
        _currentDuration = duration;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDuration(int seconds) async {
    await _settingsService.setRestTimerDuration(seconds);
    setState(() {
      _currentDuration = seconds;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    // Dark Mode check for colors if needed, but standard widgets usually adapt
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Pausen-Timer'),
                  subtitle: Text('Dauer: ${_formatDuration(_currentDuration)}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showDurationPicker(),
                ),
                // Here we can add more settings later
              ],
            ),
    );
  }

  void _showDurationPicker() {
    showDialog(
      context: context,
      builder: (context) {
        int tempSeconds = _currentDuration;
        int minutes = tempSeconds ~/ 60;
        int seconds = tempSeconds % 60;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Timer Dauer einstellen'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minutes
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Min', style: TextStyle(fontWeight: FontWeight.bold)),
                      NumberPicker(
                        value: minutes,
                        minValue: 0,
                        maxValue: 10,
                        onChanged: (value) => setState(() => minutes = value),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  // Seconds
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sek', style: TextStyle(fontWeight: FontWeight.bold)),
                      NumberPicker(
                        value: seconds,
                        minValue: 0,
                        maxValue: 59,
                        step: 5,
                        onChanged: (value) => setState(() => seconds = value),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () {
                    final total = (minutes * 60) + seconds;
                    _saveDuration(total);
                    Navigator.pop(context);
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Simple custom NumberPicker since we don't want to add a heavy dependency for just this
class NumberPicker extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final int step;
  final ValueChanged<int> onChanged;

  const NumberPicker({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value - step >= minValue
              ? () => onChanged(value - step)
              : null,
        ),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: 20),
            ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value + step <= maxValue
              ? () => onChanged(value + step)
              : null,
        ),
      ],
    );
  }
}
