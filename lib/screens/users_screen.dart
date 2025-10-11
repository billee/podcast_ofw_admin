// users_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Users',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildUsersTable(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'No users found',
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
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Display Name')),
                DataColumn(label: Text('User ID')),
                DataColumn(label: Text('Created At')),
                DataColumn(label: Text('Last Sign In')),
                DataColumn(label: Text('Subscription Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: users.map((user) {
                final data = user.data() as Map<String, dynamic>;
                return _buildUserDataRow(context, user.id, data);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildUserDataRow(
      BuildContext context, String userId, Map<String, dynamic> data) {
    final subscriptionStatus = _getSubscriptionStatus(data);

    return DataRow(
      cells: [
        // Email
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              data['email']?.toString() ?? 'No Email',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Display Name
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              data['displayName']?.toString() ?? 'No Name',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // User ID
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              userId.length > 8 ? '${userId.substring(0, 8)}...' : userId,
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Created At
        DataCell(
          Text(_formatDate(data['createdAt'])),
        ),
        // Last Sign In
        DataCell(
          Text(_formatDate(data['lastSignInTime'])),
        ),
        // Subscription Status
        DataCell(
          Chip(
            label: Text(
              subscriptionStatus,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: _getSubscriptionColor(subscriptionStatus),
          ),
        ),
        // Actions
        DataCell(
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.visibility, size: 18, color: Colors.blue),
                onPressed: () {
                  _showUserDetailsDialog(context, userId, data);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () {
                  _showDeleteDialog(
                      context, userId, data['email'] ?? 'this user');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSubscriptionStatus(Map<String, dynamic> data) {
    // Check if user is a subscriber (isSubscribed field is true)
    if (data['isSubscribed'] == true) {
      return 'SUBSCRIBER';
    }

    // If not subscribed, they are in free trial
    return 'FREE TRIAL';
  }

  Color _getSubscriptionColor(String status) {
    switch (status) {
      case 'SUBSCRIBER':
        return Colors.green;
      case 'FREE TRIAL':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = timestamp.toDate();
      return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _showUserDetailsDialog(
      BuildContext context, String userId, Map<String, dynamic> data) {
    final subscriptionStatus = _getSubscriptionStatus(data);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email:', data['email'] ?? 'N/A'),
              _buildDetailRow('Display Name:', data['displayName'] ?? 'N/A'),
              _buildDetailRow('User ID:', userId),
              _buildDetailRow('Subscription Status:', subscriptionStatus),
              _buildDetailRow(
                  'Subscribed:', data['isSubscribed'] == true ? 'Yes' : 'No'),
              _buildDetailRow('Email Verified:',
                  data['emailVerified'] == true ? 'Yes' : 'No'),
              _buildDetailRow('Created:', _formatDate(data['createdAt'])),
              _buildDetailRow(
                  'Last Sign In:', _formatDate(data['lastSignInTime'])),
              if (data['phoneNumber'] != null)
                _buildDetailRow('Phone:', data['phoneNumber']),
              if (data['photoURL'] != null)
                _buildDetailRow('Photo URL:', data['photoURL']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String userId, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "$email"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .delete();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'User deleted successfully!');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
