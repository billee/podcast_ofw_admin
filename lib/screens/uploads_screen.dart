// uploads_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/supabase_service.dart';
import '../utils/web_file_picker.dart';

class UploadsScreen extends StatefulWidget {
  const UploadsScreen({Key? key}) : super(key: key);

  @override
  _UploadsScreenState createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationMinutesController = TextEditingController();
  final _durationSecondsController = TextEditingController();

  WebFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Citations management
  final List<TextEditingController> _citationControllers = [
    TextEditingController()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Podcast'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Podcast Details Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Podcast Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Podcast Title*',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description*',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Duration*',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _durationMinutesController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Minutes',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.timer),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter minutes';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Enter valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _durationSecondsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Seconds',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.timer_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter seconds';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Enter valid number';
                                  }
                                  final seconds = int.tryParse(value) ?? 0;
                                  if (seconds >= 60) {
                                    return 'Must be 0-59';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Citations Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Citations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.green),
                              onPressed: _addCitationField,
                              tooltip: 'Add another citation',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add references, sources, or citations for this podcast',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildCitationFields(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // File Selection Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audio File*',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _selectedFile == null
                            ? Column(
                                children: [
                                  OutlinedButton(
                                    onPressed: _pickAudioFile,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.audio_file),
                                        SizedBox(width: 8),
                                        Text('Select Audio File from Computer'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Supported: MP3, M4A, WAV files',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.audio_file,
                                          color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedFile!.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            _selectedFile = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Size: ${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Type: ${_selectedFile!.type}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upload Progress
                if (_isUploading) ...[
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadPodcast,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Upload to Supabase Storage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(
                    height: 24), // Extra space at bottom for better scrolling
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCitationFields() {
    return List.generate(_citationControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _citationControllers[index],
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Citation ${index + 1}',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.format_quote),
                  suffixIcon: _citationControllers.length > 1
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => _removeCitationField(index),
                          tooltip: 'Remove citation',
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _addCitationField() {
    setState(() {
      _citationControllers.add(TextEditingController());
    });
  }

  void _removeCitationField(int index) {
    if (_citationControllers.length > 1) {
      setState(() {
        _citationControllers[index].dispose();
        _citationControllers.removeAt(index);
      });
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final webFile = await WebFilePicker.pickFile(acceptedTypes: [
        'audio/mpeg',
        'audio/mp4',
        'audio/wav',
        'audio/x-m4a',
      ]);

      if (webFile != null) {
        setState(() {
          _selectedFile = webFile;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error selecting file: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _uploadPodcast() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: "Please fill all required fields",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (_selectedFile == null) {
      Fluttertoast.showToast(
        msg: "Please select an audio file",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Get the next episode number (last episode + 1)
      final nextEpisode = await _getNextEpisodeNumber();

      // Calculate duration from user input
      final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
      final seconds = int.tryParse(_durationSecondsController.text) ?? 0;
      final totalDuration = (minutes * 60) + seconds;

      // Generate filename in the EXACT format: "podcast_timestamp_title.extension"
      final timestamp =
          DateTime.now().millisecondsSinceEpoch; // 13-digit milliseconds

      // Create a sanitized title for the filename
      String sanitizedTitle = _titleController.text.trim().toLowerCase();
      sanitizedTitle = sanitizedTitle.replaceAll(RegExp(r'[^a-z0-9]'),
          '_'); // Replace spaces/special chars with underscores

      // Get file extension from original file
      String fileExtension = _selectedFile!.name.split('.').last;

      // Generate the EXACT filename format from screenshot (NO SLASH)
      String fileName = 'podcast_${timestamp}_$sanitizedTitle.$fileExtension';

      // Upload to Supabase Storage
      final audioUrl = await SupabaseService.uploadFile(
        bucketName: 'podcasts',
        fileName: fileName,
        fileBytes: _selectedFile!.bytes,
        fileType: _selectedFile!.type,
      );

      // Collect non-empty citations
      final citations = _citationControllers
          .map((controller) => controller.text.trim())
          .where((citation) => citation.isNotEmpty)
          .toList();

      // Save to Firestore with CORRECT field names including citations
      await FirebaseFirestore.instance.collection('podcasts').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'audioUrl': audioUrl,
        'audioFileName':
            fileName, // This will match exactly what's in Supabase storage
        'fileSize': _selectedFile!.size,
        'storageProvider': 'supabase',
        'uploadedAt': FieldValue.serverTimestamp(),
        'createAt': FieldValue.serverTimestamp(),
        'duration': totalDuration,
        'episode': nextEpisode,
        'isActive': true,
        'citations': citations, // Add citations array
      });

      // Reset form and show success
      _formKey.currentState!.reset();
      setState(() {
        _selectedFile = null;
        _isUploading = false;
        _uploadProgress = 0.0;
        // Reset citations but keep one empty field
        for (var controller in _citationControllers) {
          controller.dispose();
        }
        _citationControllers.clear();
        _citationControllers.add(TextEditingController());
      });

      Fluttertoast.showToast(
        msg: "Podcast Episode $nextEpisode uploaded successfully!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      Fluttertoast.showToast(
        msg: "Upload failed: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _simulateProgress() async {
    for (int i = 0; i <= 100; i += 10) {
      if (!_isUploading) break;
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _uploadProgress = i / 100;
      });
    }
  }

  Future<int> _getNextEpisodeNumber() async {
    try {
      // Get the last podcast to determine the next episode number
      final querySnapshot = await FirebaseFirestore.instance
          .collection('podcasts')
          .orderBy('episode', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final lastEpisode = querySnapshot.docs.first.data()['episode'] as int;
        return lastEpisode + 1;
      }

      // If no podcasts exist yet, start with episode 1
      return 1;
    } catch (e) {
      print('Error getting next episode number: $e');
      // Fallback: try to get the count of documents
      try {
        final countQuery = await FirebaseFirestore.instance
            .collection('podcasts')
            .count()
            .get();
        return countQuery.count + 1;
      } catch (countError) {
        print('Count also failed: $countError');
        return 1;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationMinutesController.dispose();
    _durationSecondsController.dispose();
    // Dispose all citation controllers
    for (var controller in _citationControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
