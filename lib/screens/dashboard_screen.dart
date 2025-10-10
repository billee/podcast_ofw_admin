// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'uploads_screen.dart';
import 'podcasts_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OFW Podcasts Admin'),
        backgroundColor: Colors.blue[700],
        elevation: 1,
      ),
      drawer: _buildDrawer(context, authService),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome, ${authService.currentUser?.email ?? 'Admin'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats Overview
            const Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  title: 'Total Podcasts',
                  value: '4',
                  icon: Icons.podcasts,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  title: 'Active Users',
                  value: '0',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Podcast Management Section
            const Text(
              'Podcast Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildPodcastList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new podcast functionality
          _showAddPodcastDialog(context);
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthService authService) {
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
                Text(
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
                  style: TextStyle(
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
              Navigator.pop(context);
            },
          ),

          // Uploads Menu Item - ADD THIS
          ListTile(
            leading: const Icon(Icons.upload, color: Colors.teal),
            title: const Text('Uploads'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadsScreen()),
              );
            },
          ),

          // Podcasts Menu Item
          ListTile(
            leading: const Icon(Icons.podcasts, color: Colors.green),
            title: const Text('Podcasts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PodcastsScreen()),
              );
            },
          ),

          // Users Menu Item
          ListTile(
            leading: const Icon(Icons.people, color: Colors.orange),
            title: const Text('Users'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // Analytics Menu Item
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.purple),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // Settings Menu Item
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // Divider
          const Divider(),

          // Logout Menu Item - Fixed
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              // Get authService again to ensure we have the latest instance
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodcastList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('podcasts').snapshots(),
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

        return ListView.builder(
            itemCount: podcasts.length,
            itemBuilder: (context, index) {
              final podcast = podcasts[index];
              final data = podcast.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'E${data['episode'] ?? '?'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                      Icon(
                        data['isActive'] == true
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: data['isActive'] == true
                            ? Colors.green
                            : Colors.red,
                        size: 16,
                      ),
                    ],
                  ),
                  title: Text(data['title'] ?? 'Untitled'),
                  subtitle: Text(data['description'] ?? 'No description'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditPodcastDialog(context, podcast.id, data);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deletePodcast(context, podcast.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            });
      },
    );
  }

  void _showAddPodcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Podcast'),
        content:
            const Text('Add podcast functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditPodcastDialog(
      BuildContext context, String podcastId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Podcast'),
        content:
            const Text('Edit podcast functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deletePodcast(BuildContext context, String podcastId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Podcast'),
        content: const Text('Are you sure you want to delete this podcast?'),
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
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
