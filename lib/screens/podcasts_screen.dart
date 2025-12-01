// podcasts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/uploads_screen.dart';
import '../screens/users_screen.dart';
import '../components/rich_text_citation_editor.dart';
import '../components/edit_podcast_dialog.dart';

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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      key: _scaffoldKey, // Added key to access scaffold state
      appBar: AppBar(
        title: const Text('Podcasts Management'),
        backgroundColor: Colors.blue[700],
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Fixed: using scaffold key
          },
        ),
      ),
      drawer: _buildDrawer(context),
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
                          _currentPage = 0; // Reset to first page when sort order changes
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

            // Podcasts table with pagination
            Expanded(
              child: _buildPodcastsTableWithPagination(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue[700],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'OFW Podcasts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authService.currentUser?.email ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Dashboard Menu Item
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blue),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),

          // Uploads Menu Item
          ListTile(
            leading: const Icon(Icons.upload, color: Colors.teal),
            title: const Text('Uploads'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadsScreen()),
              );
            },
          ),

          // Podcasts Menu Item (Current Page)
          ListTile(
            leading: const Icon(Icons.podcasts, color: Colors.green),
            title: const Text('Podcasts'),
            tileColor: Colors.blue[50], // Highlight current page
            onTap: () {
              Navigator.pop(context); // Just close drawer since we're already here
            },
          ),

          // Users Menu Item
          ListTile(
            leading: const Icon(Icons.people, color: Colors.orange),
            title: const Text('Users'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersScreen()),
              );
            },
          ),

          // Analytics Menu Item
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.purple),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // TODO: Implement analytics screen
            },
          ),

          // Settings Menu Item
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // TODO: Implement settings screen
            },
          ),

          // Divider
          const Divider(),

          // Logout Menu Item
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              await authService.logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastsTableWithPagination(BuildContext context) {
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

        return Column(
          children: [
            // Table content
            Expanded(
              child: _buildTableContent(context, paginatedPodcasts),
            ),

            // Pagination controls - built inside the StreamBuilder
            _buildPaginationControls(totalPages),
          ],
        );
      },
    );
  }

  Widget _buildTableContent(BuildContext context, List<QueryDocumentSnapshot> paginatedPodcasts) {
    if (paginatedPodcasts.isEmpty) {
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
                    dataTextStyle: const TextStyle(fontSize: 12), // Decreased font size by 1
                    headingTextStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ), // Decreased header font size by 1
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
  }

  Widget _buildPaginationControls(int totalPages) {
    final hasPreviousPage = _currentPage > 0;
    final hasNextPage = _currentPage < totalPages - 1 && totalPages > 0;

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
              'Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
        // Active Status
        DataCell(
          Icon(
            data['isActive'] == true ? Icons.check_circle : Icons.cancel,
            color: data['isActive'] == true ? Colors.green : Colors.red,
            size: 16,
          ),
        ),
        // Actions
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditPodcastDialog(
                      podcastId: podcastId,
                      data: data,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                onPressed: () {
                  _showDeleteDialog(
                      context, podcastId, data['title'] ?? 'this podcast');
                },
              ),
              IconButton(
                icon: const Icon(Icons.audiotrack, size: 16, color: Colors.green),
                onPressed: () async {
                  final audioUrl = data['audioUrl'];
                  if (audioUrl != null && audioUrl.isNotEmpty) {
                    try {
                      await launchUrl(
                        Uri.parse(audioUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: 'Cannot open audio URL: $e',
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  } else {
                    Fluttertoast.showToast(
                      msg: 'No audio URL available',
                      backgroundColor: Colors.orange,
                      textColor: Colors.white,
                    );
                  }
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
}