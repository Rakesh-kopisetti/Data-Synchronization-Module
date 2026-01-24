import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/presentation/providers/note_provider.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note;

  const NoteDetailScreen({super.key, this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final noteProvider = context.read<NoteProvider>();
      
      if (widget.note == null) {
        // Create new note
        await noteProvider.createNote(
          _titleController.text,
          _contentController.text,
        );
      } else {
        // Update existing note
        await noteProvider.updateNote(
          widget.note!.id,
          _titleController.text,
          _contentController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.note == null ? 'Note created' : 'Note updated',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (_titleController.text.isNotEmpty &&
              (widget.note == null ||
                  (_titleController.text != widget.note!.title ||
                      _contentController.text != widget.note!.content))) {
            final shouldPop = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Discard Changes'),
                    content: const Text('Do you want to discard changes?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (shouldPop && mounted) {
              Navigator.pop(context);
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveNote,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Content',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 10,
                minLines: 5,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveNote,
                    child: Text(
                      widget.note == null ? 'Create Note' : 'Update Note',
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
