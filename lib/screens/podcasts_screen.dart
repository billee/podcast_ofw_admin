// podcasts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({Key? key}) : super(key: key);

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  // Add state for sort order
  bool _sortAscending =
      false; // false = descending (newest first), true = ascending (oldest first)

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 10; // Number of items per page
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _currentPage = 0; // Reset to first page when searching
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            // Header with sort controls
            Row(
              children: [
                const Text(
                  'All Podcasts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Sort order dropdown
                Row(
                  children: [
                    const Text(
                      'Sort by Episode:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<bool>(
                      value: _sortAscending,
                      icon: const Icon(Icons.sort),
                      items: const [
                        DropdownMenuItem<bool>(
                          value: false,
                          child: Text('Newest First'),
                        ),
                        DropdownMenuItem<bool>(
                          value: true,
                          child: Text('Oldest First'),
                        ),
                      ],
                      onChanged: (bool? newValue) {
                        setState(() {
                          _sortAscending = newValue ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Box
            Card(
              elevation: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search podcasts by title...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _buildPodcastsTable(context),
            ),

            // Pagination Controls
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastsTable(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('podcasts')
          .orderBy('episode', descending: !_sortAscending)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allPodcasts = snapshot.data?.docs ?? [];

        // Apply search filter
        final filteredPodcasts = allPodcasts.where((podcast) {
          if (_searchQuery.isEmpty) return true;
          final data = podcast.data() as Map<String, dynamic>;
          final title = data['title']?.toString().toLowerCase() ?? '';
          return title.contains(_searchQuery);
        }).toList();

        // Update total items count
        _totalItems = filteredPodcasts.length;

        // Calculate pagination
        final totalPages = (_totalItems / _pageSize).ceil();
        final startIndex = _currentPage * _pageSize;
        final endIndex = startIndex + _pageSize;
        final paginatedPodcasts = filteredPodcasts.sublist(
          startIndex.clamp(0, filteredPodcasts.length),
          endIndex.clamp(0, filteredPodcasts.length),
        );

        if (filteredPodcasts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No podcasts found'
                      : 'No podcasts found for "$_searchQuery"',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Results count
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    'Showing ${paginatedPodcasts.length} of $_totalItems podcasts',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('Search: "$_searchQuery"'),
                      backgroundColor: Colors.blue[50],
                    ),
                  ],
                ],
              ),
            ),

            // Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) => Colors.blue[50],
                    ),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Episode')),
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Duration')),
                      DataColumn(label: Text('File Size')),
                      DataColumn(label: Text('Upload Date')),
                      DataColumn(label: Text('Citations')),
                      DataColumn(label: Text('Storage')),
                      DataColumn(label: Text('Active')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: paginatedPodcasts.map((podcast) {
                      final data = podcast.data() as Map<String, dynamic>;
                      return _buildDataRow(context, podcast.id, data);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_totalItems / _pageSize).ceil();
    final hasPreviousPage = _currentPage > 0;
    final hasNextPage = _currentPage < totalPages - 1 && totalPages > 0;

    if (totalPages <= 1)
      return const SizedBox(); // Hide pagination if only one page

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: hasPreviousPage
                  ? () {
                      setState(() {
                        _currentPage--;
                      });
                    }
                  : null,
            ),
            const SizedBox(width: 8),

            // Page info
            Text(
              'Page ${_currentPage + 1} of $totalPages',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),

            // Next button
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: hasNextPage
                  ? () {
                      setState(() {
                        _currentPage++;
                      });
                    }
                  : null,
            ),

            const Spacer(),

            // Items per page info
            Text(
              '$_pageSize per page',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(
      BuildContext context, String podcastId, Map<String, dynamic> data) {
    final citations = List<String>.from(data['citations'] ?? []);

    return DataRow(
      cells: [
        // ID Column - Display the Firestore document ID
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              _truncateId(podcastId),
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'Monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
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
            width: 200,
            child: Text(
              data['title']?.toString() ?? 'No Title',
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
        // Upload Date - Use createAt instead of uploadedAt
        DataCell(
          Text(_formatDate(data['createAt'] ?? data['uploadedAt'])),
        ),
        // Citations Count
        DataCell(
          Chip(
            label: Text(
              '${citations.length}',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            backgroundColor: citations.isNotEmpty ? Colors.blue : Colors.grey,
          ),
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
        // Active Status
        DataCell(
          Icon(
            data['isActive'] == true ? Icons.check_circle : Icons.cancel,
            color: data['isActive'] == true ? Colors.green : Colors.red,
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

  String _truncateId(String id) {
    // Truncate long IDs for better display, show first 8 and last 4 characters
    if (id.length > 15) {
      return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
    }
    return id;
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
    bool isActive = data['isActive'] ?? true;

    // Citations management for edit dialog
    final List<TextEditingController> citationControllers = [];
    final List<double> citationHeights = [];
    final List<String> initialCitations =
        List<String>.from(data['citations'] ?? []);

    // Initialize citation controllers with existing citations
    for (String citation in initialCitations) {
      citationControllers.add(TextEditingController(text: citation));
      // Set initial height based on content length
      final lineCount = citation.split('\n').length;
      citationHeights.add((lineCount * 20.0 + 40.0).clamp(60.0, 200.0));
    }
    // Add one empty citation field if there are no citations
    if (citationControllers.isEmpty) {
      citationControllers.add(TextEditingController());
      citationHeights.add(100.0);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                          onPressed: () {
                            setState(() {
                              citationControllers.add(TextEditingController());
                              citationHeights.add(100.0);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._buildCitationFieldsForEdit(
                        citationControllers, citationHeights, setState),
                  ],
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      isActive = value ?? true;
                    });
                  },
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
                // Collect non-empty citations
                final citations = citationControllers
                    .map((controller) => controller.text.trim())
                    .where((citation) => citation.isNotEmpty)
                    .toList();

                await FirebaseFirestore.instance
                    .collection('podcasts')
                    .doc(podcastId)
                    .update({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'isActive': isActive,
                  'citations': citations, // Update citations
                });

                // Dispose controllers
                for (var controller in citationControllers) {
                  controller.dispose();
                }

                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Podcast updated successfully!');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCitationFieldsForEdit(
      List<TextEditingController> controllers,
      List<double> heights,
      StateSetter setState) {
    return List.generate(controllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Citation ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (controllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle,
                        color: Colors.red, size: 18),
                    onPressed: () {
                      setState(() {
                        controllers[index].dispose();
                        controllers.removeAt(index);
                        heights.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Expandable text area for citations
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SizedBox(
                height: heights[index],
                child: TextField(
                  controller: controllers[index],
                  maxLines: null, // Allows unlimited lines
                  expands:
                      true, // Makes the field expand to fill available height
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                    hintText: 'Enter citation text...',
                  ),
                  onChanged: (text) {
                    // Auto-resize based on content
                    _autoResizeCitationField(index, heights, text, setState);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }

  void _autoResizeCitationField(
      int index, List<double> heights, String text, StateSetter setState) {
    // Auto-resize based on line count
    final lineCount = text.split('\n').length;
    final newHeight = (lineCount * 20.0 + 40.0).clamp(60.0, 400.0);

    if ((newHeight - heights[index]).abs() > 10) {
      setState(() {
        heights[index] = newHeight;
      });
    }
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
