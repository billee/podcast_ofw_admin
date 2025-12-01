import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'rich_text_citation_editor.dart';

class EditPodcastDialog extends StatefulWidget {
  final String podcastId;
  final Map<String, dynamic> data;

  const EditPodcastDialog({
    Key? key,
    required this.podcastId,
    required this.data,
  }) : super(key: key);

  @override
  State<EditPodcastDialog> createState() => _EditPodcastDialogState();
}

class _EditPodcastDialogState extends State<EditPodcastDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isActive;
  late List<String> _citations;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.data['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.data['description'] ?? '');
    _isActive = widget.data['isActive'] ?? true;
    
    // Initialize citations
    _citations = List<String>.from(widget.data['citations'] ?? []);
    if (_citations.isEmpty) {
      _citations.add('');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addCitation() {
    setState(() {
      _citations.add('');
    });
  }

  void _removeCitation(int index) {
    if (_citations.length > 1) {
      setState(() {
        _citations.removeAt(index);
      });
    }
  }

  void _updateCitation(int index, String text) {
    _citations[index] = text;
  }

  Future<void> _savePodcast() async {
    try {
      // Collect non-empty citations
      final finalCitations = _citations
          .where((citation) => citation.trim().isNotEmpty)
          .toList();

      await FirebaseFirestore.instance
          .collection('podcasts')
          .doc(widget.podcastId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isActive': _isActive,
        'citations': finalCitations,
      });

      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: 'Podcast updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error updating podcast: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minWidth: MediaQuery.of(context).size.width * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Edit Podcast',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Citations Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Citations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.green, size: 20),
                              onPressed: _addCitation,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._buildCitationFields(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CheckboxListTile(
                      title: const Text('Active'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value ?? true;
                        });
                      },
                    ),
                    
                    // Extra space at bottom
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Footer with buttons
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8.0),
                  bottomRight: Radius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _savePodcast,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCitationFields() {
    return List.generate(_citations.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: RichTextCitationEditor(
          key: ValueKey('citation_$index'),
          initialText: _citations[index],
          label: 'Citation ${index + 1}',
          showRemoveButton: _citations.length > 1,
          onTextChanged: (text) => _updateCitation(index, text),
          onRemove: _citations.length > 1 ? () => _removeCitation(index) : null,
        ),
      );
    });
  }
}