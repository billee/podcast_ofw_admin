// podcasts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PodcastsScreen extends StatelessWidget {
  const PodcastsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcasts Management'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Podcasts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildPodcastsTable(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastsTable(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('podcasts')
          .orderBy('episode', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final podcasts = snapshot.data?.docs ?? [];

        if (podcasts.isEmpty) {
          return const Center(
            child: Text(
              'No podcasts found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) => Colors.blue[50],
              ),
              columns: const [
                DataColumn(label: Text('Episode')),
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Duration')),
                DataColumn(label: Text('File Size')),
                DataColumn(label: Text('Upload Date')),
                DataColumn(label: Text('Storage')),
                DataColumn(label: Text('Actions')),
              ],
              rows: podcasts.map((podcast) {
                final data = podcast.data() as Map<String, dynamic>;
                return _buildDataRow(context, podcast.id, data);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(
      BuildContext context, String podcastId, Map<String, dynamic> data) {
    return DataRow(
      cells: [
        // Episode
        DataCell(
          Text(
            'E${data['episode']?.toString() ?? 'N/A'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // Title
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              data['title']?.toString() ?? 'No Title',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        // Description
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              data['description']?.toString() ?? 'No Description',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        // Duration
        DataCell(
          Text(_formatDuration(data['duration'] ?? 0)),
        ),
        // File Size
        DataCell(
          Text(_formatFileSize(data['fileSize'] ?? 0)),
        ),
        // Upload Date
        DataCell(
          Text(_formatDate(data['uploadedAt'])),
        ),
        // Storage Provider
        DataCell(
          Chip(
            label: Text(
              data['storageProvider']?.toString().toUpperCase() ?? 'UNKNOWN',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            backgroundColor: _getStorageColor(data['storageProvider']),
          ),
        ),
        // Actions
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: () {
                  _showEditDialog(context, podcastId, data);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () {
                  _showDeleteDialog(
                      context, podcastId, data['title'] ?? 'this podcast');
                },
              ),
              IconButton(
                icon:
                    const Icon(Icons.audiotrack, size: 18, color: Colors.green),
                onPressed: () {
                  _showAudioUrlDialog(context, data['audioUrl']);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'N/A';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = timestamp.toDate();
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Color _getStorageColor(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'supabase':
        return Colors.green;
      case 'manual':
        return Colors.orange;
      case 'external':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showEditDialog(
      BuildContext context, String podcastId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descriptionController =
        TextEditingController(text: data['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Podcast'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('podcasts')
                  .doc(podcastId)
                  .update({
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
              });
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Podcast updated successfully!');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String podcastId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Podcast'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('podcasts')
                  .doc(podcastId)
                  .delete();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Podcast deleted successfully!');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAudioUrlDialog(BuildContext context, String? audioUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio URL'),
        content: SelectableText(
          audioUrl ?? 'No URL available',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (audioUrl != null && audioUrl.isNotEmpty)
            TextButton(
              onPressed: () {
                // You can add functionality to copy to clipboard or open URL
                Fluttertoast.showToast(msg: 'URL: $audioUrl');
              },
              child: const Text('Copy'),
            ),
        ],
      ),
    );
  }
}
