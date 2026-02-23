import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/diary_entry.dart';

class AddEntryScreen extends StatefulWidget {
  final DiaryEntry? entry;

  const AddEntryScreen({super.key, this.entry});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _selectedDate = widget.entry!.date;
      _titleController.text = widget.entry!.title ?? '';
      _contentController.text = widget.entry!.content;
    } else {
      _selectedDate = DateTime.now();
    }
    // Issue #3: Date format dd.MM.yyyy
    _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim().isEmpty ? null : _titleController.text.trim();
      final content = _contentController.text;

      if (widget.entry == null) {
        // Create new
        final entry = DiaryEntry(
          date: _selectedDate,
          title: title,
          content: content,
        );
        await DatabaseHelper.instance.create(entry);
      } else {
        // Update existing
        final entry = widget.entry!.copyWith(
          date: _selectedDate,
          title: title,
          content: content,
        );
        await DatabaseHelper.instance.update(entry);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // Return true to indicate saved/updated
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text('Möchtest du diesen Eintrag wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nein'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ja'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.entry?.id != null) {
      await DatabaseHelper.instance.delete(widget.entry!.id!);
      if (!mounted) return;
      Navigator.of(context).pop(true); // Return true to indicate change (deletion)
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Eintrag bearbeiten' : 'Neuer Eintrag'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Löschen',
              onPressed: _deleteEntry,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Datum',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              // Issue #1: Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Tagebucheintrag',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte gib einen Text ein';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveEntry,
                  icon: const Icon(Icons.save),
                  label: const Text('SPEICHERN'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
