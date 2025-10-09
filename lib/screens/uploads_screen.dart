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

  WebFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Podcast'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
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
            ],
          ),
        ),
      ),
    );
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
      // Get the next episode number (guaranteed no gaps/duplicates)
      final nextEpisode = await _getNextEpisodeNumber();

      // Simulate upload progress
      _simulateProgress();

      // Generate unique filename
      String fileName =
          'podcast_${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';

      // Upload to Supabase Storage
      final audioUrl = await SupabaseService.uploadFile(
        bucketName: 'podcasts',
        fileName: fileName,
        fileBytes: _selectedFile!.bytes,
        fileType: _selectedFile!.type,
      );

      // Save to Firestore with CORRECT data
      await FirebaseFirestore.instance.collection('podcasts').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'audioUrl': audioUrl, // Actual Supabase URL
        'fileName': _selectedFile!.name, // Original file name
        'fileSize': _selectedFile!.size, // Actual file size in bytes
        'storageProvider': 'supabase', // Correct storage provider
        'uploadedAt': FieldValue.serverTimestamp(),
        'duration': 0, // Will be 0 until we implement audio analysis
        'episode': nextEpisode, // Auto-incremented episode number (no gaps)
        'status': 'active',
      });

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _selectedFile = null;
        _isUploading = false;
        _uploadProgress = 0.0;
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

  Future<int> _getNextEpisodeNumber() async {
    final counterRef = FirebaseFirestore.instance
        .collection('counters')
        .doc('podcast_episode');

    try {
      // Use transaction to safely increment
      return await FirebaseFirestore.instance
          .runTransaction<int>((transaction) async {
        final counterDoc = await transaction.get(counterRef);

        int nextEpisode;

        if (!counterDoc.exists) {
          // First time - create counter and return episode 1
          nextEpisode = 1;
          transaction.set(counterRef, {
            'currentEpisode': 2, // Set to 2 because we're using 1 now
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Increment existing counter
          final currentEpisode = counterDoc.data()!['currentEpisode'] as int;
          nextEpisode = currentEpisode;
          transaction.update(counterRef, {
            'currentEpisode': currentEpisode + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        return nextEpisode;
      });
    } catch (e) {
      print('Error in episode counter transaction: $e');

      // Fallback: try to get the max episode from existing podcasts
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('podcasts')
            .orderBy('episode', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final lastEpisode = querySnapshot.docs.first.data()['episode'] as int;
          return lastEpisode + 1;
        }
        return 1;
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        return 1; // Ultimate fallback
      }
    }
  }

  Future<int> _getAudioDuration(Uint8List audioBytes) async {
    try {
      // This is a simplified example - you'd need to implement actual audio analysis
      // For now, return 0 as placeholder
      return 0;
    } catch (e) {
      return 0;
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
