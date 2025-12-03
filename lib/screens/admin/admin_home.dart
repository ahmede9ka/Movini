// lib/screens/admin/admin_home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_stats.dart';
import 'admin_movie_list.dart';
import '../../services/admin_firebase_service.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final AdminFirebaseService _adminService = AdminFirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _stats = {
    'totalMovies': 0,
    'totalUsers': 0,
    'todaysViews': 0,
    'totalFavorites': 0,
    'activeUsers': 0,
    'revenue': 0.0,
  };

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _topMovies = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _showAddUserForm = false;
  bool _showAddMovieForm = false;

  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userFirstNameController = TextEditingController();
  final TextEditingController _userLastNameController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _movieTitleController = TextEditingController();
  final TextEditingController _movieYearController = TextEditingController();
  final TextEditingController _movieDescriptionController = TextEditingController();
  final TextEditingController _moviePosterUrlController = TextEditingController();
  final TextEditingController _movieGenreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await Future.wait([
        _loadStats(),
        _loadUsers(),
        _loadRecentActivities(),
        _loadTopMovies(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: $e';
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      // Get total movies directly from Movies collection
      final moviesQuery = await _firestore.collection('Movies').get();
      final totalMovies = moviesQuery.docs.length;

      // Get total users
      final usersQuery = await _firestore.collection('users').get();
      final totalUsers = usersQuery.docs.length;

      // Get today's views
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      int todaysViews = 0;
      try {
        final viewsQuery = await _firestore
            .collection('movie_views')
            .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
            .where('timestamp', isLessThan: endOfDay)
            .get();
        todaysViews = viewsQuery.docs.length;
      } catch (e) {
        todaysViews = 0;
      }

      // Get total favorites
      int totalFavorites = 0;
      try {
        final users = await _firestore.collection('users').get();
        for (final userDoc in users.docs) {
          final favs = await _firestore
              .collection('favorites')
              .doc(userDoc.id)
              .collection('Movies')
              .get();
          totalFavorites += favs.docs.length;
        }
      } catch (e) {
        totalFavorites = 0;
      }

      // Get active users (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      int activeUsers = 0;
      try {
        final activeUsersQuery = await _firestore
            .collection('users')
            .where('lastActive', isGreaterThanOrEqualTo: weekAgo)
            .get();
        activeUsers = activeUsersQuery.docs.length;
      } catch (e) {
        activeUsers = totalUsers;
      }

      setState(() {
        _stats = {
          'totalMovies': totalMovies,
          'totalUsers': totalUsers,
          'todaysViews': todaysViews,
          'totalFavorites': totalFavorites,
          'activeUsers': activeUsers,
          'revenue': 0.0,
        };
      });
    } catch (e) {
      setState(() {
        _stats = {
          'totalMovies': 0,
          'totalUsers': 0,
          'todaysViews': 0,
          'totalFavorites': 0,
          'activeUsers': 0,
          'revenue': 0.0,
        };
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final query = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      final users = query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'name': '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim(),
          'photoURL': data['photoURL'] ?? '',
          'role': data['role'] ?? 'user',
          'isActive': data['isActive'] ?? true,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'lastLogin': (data['lastLogin'] as Timestamp?)?.toDate(),
        };
      }).toList();

      setState(() {
        _users = users;
      });
    } catch (e) {
      setState(() {
        _users = [];
      });
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final query = await _firestore
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final activities = query.docs.map((doc) {
        final data = doc.data();
        dynamic timestamp = data['timestamp'];
        if (timestamp is Timestamp) {
          timestamp = timestamp.toDate();
        }
        return {
          'id': doc.id,
          'type': data['type'] ?? '',
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'timestamp': timestamp,
          'userId': data['userId'],
          'userName': data['userName'],
        };
      }).toList();

      setState(() {
        _recentActivities = activities;
      });
    } catch (e) {
      // Create mock activities if collection doesn't exist
      List<Map<String, dynamic>> activities = [];

      activities.add({
        'type': 'system_start',
        'title': 'Admin Dashboard Loaded',
        'description': 'System initialized successfully',
        'timestamp': DateTime.now(),
      });

      setState(() {
        _recentActivities = activities;
      });
    }
  }

  Future<void> _loadTopMovies() async {
    try {
      final query = await _firestore
          .collection('Movies')
          .get();

      final movies = query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'year': data['year'] ?? '',
          'genre': data['genre'] is List ? data['genre'] : [],
          'rating': data['rating'] ?? 0.0,
          'posterUrl': data['posterUrl'] ?? '',
          'views': data['views'] ?? 0,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
        };
      }).toList();

      setState(() {
        _topMovies = movies;
      });
    } catch (e) {
      setState(() {
        _topMovies = [];
      });
    }
  }

  Future<void> _addUser() async {
    if (_userEmailController.text.isEmpty ||
        _userFirstNameController.text.isEmpty ||
        _userPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final newUser = {
        'email': _userEmailController.text,
        'prenom': _userFirstNameController.text,
        'nom': _userLastNameController.text,
        'password': _userPasswordController.text,
        'role': 'user',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'photoURL': '',
      };

      await _firestore.collection('users').add(newUser);

      // Clear form
      _userEmailController.clear();
      _userFirstNameController.clear();
      _userLastNameController.clear();
      _userPasswordController.clear();

      setState(() {
        _showAddUserForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload users
      await _loadUsers();
      await _loadStats();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addMovie() async {
    if (_movieTitleController.text.isEmpty ||
        _movieYearController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and year'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Convert genre string to list
      List<String> genres = [];
      if (_movieGenreController.text.isNotEmpty) {
        genres = _movieGenreController.text.split(',').map((genre) => genre.trim()).toList();
      }

      final newMovie = {
        'title': _movieTitleController.text,
        'year': int.tryParse(_movieYearController.text) ?? DateTime.now().year,
        'description': _movieDescriptionController.text,
        'posterUrl': _moviePosterUrlController.text,
        'genre': genres.isNotEmpty ? genres : ['Action', 'Drama'],
        'rating': 0.0,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add movie to the Movies collection
      await _firestore.collection('Movies').add(newMovie);

      // Clear form
      _movieTitleController.clear();
      _movieYearController.clear();
      _movieDescriptionController.clear();
      _moviePosterUrlController.clear();
      _movieGenreController.clear();

      setState(() {
        _showAddMovieForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movie added successfully to Movies collection'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload movies and stats
      await _loadTopMovies();
      await _loadStats();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding movie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${isActive ? 'activated' : 'deactivated'}'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User role updated to $role'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$userName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('users').doc(userId).delete();

                // Try to delete user's favorites
                try {
                  await _firestore.collection('favorites').doc(userId).delete();
                } catch (e) {
                  // Ignore if favorites don't exist
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );

                await _loadUsers();
                await _loadStats();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting user: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Movie Manager Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total Movies: ${_stats['totalMovies']}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              _scrollToUsers();
            },
          ),
          ListTile(
            leading: const Icon(Icons.movie),
            title: const Text('Movie Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminMovieList()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminStats()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add User'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _showAddUserForm = true;
                _showAddMovieForm = false;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.movie_creation),
            title: const Text('Add Movie'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _showAddMovieForm = true;
                _showAddUserForm = false;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () {
              _confirmLogout(context);
            },
          ),
        ],
      ),
    );
  }

  void _scrollToUsers() {
    Future.delayed(const Duration(milliseconds: 100), () {
      Scrollable.ensureVisible(
        _usersKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  final GlobalKey _usersKey = GlobalKey();

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, Admin!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Movie Manager Admin Panel',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.movie, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              '${_stats['totalMovies']} movies in collection',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Total Movies',
          value: '${_stats['totalMovies'] ?? 0}',
          icon: Icons.movie,
          color: Colors.blue,
          subtitle: 'From Movies collection',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminMovieList()),
            );
          },
        ),
        _buildStatCard(
          title: 'Total Users',
          value: '${_stats['totalUsers'] ?? 0}',
          icon: Icons.people,
          color: Colors.green,
          subtitle: 'Registered users',
          onTap: _scrollToUsers,
        ),
        _buildStatCard(
          title: "Today's Views",
          value: '${_stats['todaysViews'] ?? 0}',
          icon: Icons.visibility,
          color: Colors.orange,
          subtitle: 'Movie views today',
          onTap: () {},
        ),
        _buildStatCard(
          title: 'Total Favorites',
          value: '${_stats['totalFavorites'] ?? 0}',
          icon: Icons.favorite,
          color: Colors.red,
          subtitle: 'All favorite entries',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddUserForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '➕ Add New User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showAddUserForm = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userEmailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userFirstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _userLastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addUser,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMovieForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎬 Add New Movie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showAddMovieForm = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _movieTitleController,
              decoration: const InputDecoration(
                labelText: 'Movie Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                hintText: 'Enter movie title',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _movieYearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Year *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      hintText: '2024',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _movieGenreController,
                    decoration: const InputDecoration(
                      labelText: 'Genres',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                      hintText: 'Action, Drama, Comedy',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _movieDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                hintText: 'Enter movie description...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _moviePosterUrlController,
              decoration: const InputDecoration(
                labelText: 'Poster URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
                hintText: 'https://example.com/poster.jpg',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addMovie,
                    icon: const Icon(Icons.movie),
                    label: const Text('Add Movie to Collection'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Movie will be added to "Movies" collection in Firebase. Total movies count will update automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    return Card(
      key: _usersKey,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '👥 User Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAddUserForm = true;
                      _showAddMovieForm = false;
                    });
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add User'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_users.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _users.map((user) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: user['photoURL'] != null && user['photoURL'].isNotEmpty
                            ? NetworkImage(user['photoURL'])
                            : null,
                        child: user['photoURL'] == null || user['photoURL'].isEmpty
                            ? const Icon(Icons.person, color: Colors.blue)
                            : null,
                      ),
                      title: Text(
                        user['name'] ?? 'No Name',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? 'No Email'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text(user['role']?.toUpperCase() ?? 'USER'),
                                backgroundColor: user['role'] == 'admin'
                                    ? Colors.green.shade100
                                    : Colors.blue.shade100,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(user['isActive'] == true ? 'ACTIVE' : 'INACTIVE'),
                                backgroundColor: user['isActive'] == true
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Row(
                              children: [
                                Icon(
                                  user['isActive'] == true ? Icons.block : Icons.check_circle,
                                  size: 20,
                                  color: user['isActive'] == true ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(user['isActive'] == true ? 'Deactivate' : 'Activate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'make_admin',
                            child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings, size: 20, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Make Admin'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'toggle_status') {
                            _updateUserStatus(user['id'], !(user['isActive'] == true));
                          } else if (value == 'make_admin') {
                            _updateUserRole(user['id'], 'admin');
                          } else if (value == 'delete') {
                            _deleteUser(user['id'], user['name'] ?? 'User');
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMoviesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎬 Recent Movies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminMovieList()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_topMovies.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.movie, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No movies found in Movies collection',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Movie'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _topMovies.map((movie) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: movie['posterUrl'] != null && movie['posterUrl'].isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(movie['posterUrl']),
                            fit: BoxFit.cover,
                          )
                              : null,
                          color: Colors.grey[200],
                        ),
                        child: movie['posterUrl'] == null || movie['posterUrl'].isEmpty
                            ? const Icon(Icons.movie, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        movie['title'] ?? 'Unknown Title',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${movie['year'] ?? ''} • ${(movie['genre'] is List ? (movie['genre'] as List).join(', ') : '')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(
                            label: Text('${movie['rating'] ?? 0.0} ⭐'),
                            backgroundColor: Colors.amber.shade100,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${movie['views'] ?? 0} 👁️',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add User'),
                  backgroundColor: Colors.green.shade100,
                  onPressed: () {
                    setState(() {
                      _showAddUserForm = true;
                      _showAddMovieForm = false;
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.movie, size: 18),
                  label: const Text('Add Movie'),
                  backgroundColor: Colors.blue.shade100,
                  onPressed: () {
                    setState(() {
                      _showAddMovieForm = true;
                      _showAddUserForm = false;
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.people, size: 18),
                  label: const Text('View Users'),
                  backgroundColor: Colors.purple.shade100,
                  onPressed: _scrollToUsers,
                ),
                ActionChip(
                  avatar: const Icon(Icons.movie_filter, size: 18),
                  label: const Text('View Movies'),
                  backgroundColor: Colors.orange.shade100,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminMovieList()),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Analytics'),
                  backgroundColor: Colors.teal.shade100,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminStats()),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh Data'),
                  backgroundColor: Colors.grey.shade200,
                  onPressed: _refreshData,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 System Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Total Users', _stats['totalUsers'] ?? 0, Colors.green),
            _buildStatusRow('Total Movies', _stats['totalMovies'] ?? 0, Colors.blue,
                subtitle: 'From Movies collection'),
            _buildStatusRow('Active Users', _stats['activeUsers'] ?? 0, Colors.orange),
            _buildStatusRow("Today's Views", _stats['todaysViews'] ?? 0, Colors.purple),
            _buildStatusRow('Total Favorites', _stats['totalFavorites'] ?? 0, Colors.red),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.storage, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Movies Collection: ${_stats['totalMovies']} movies',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All movies are stored in the "Movies" collection in Firebase',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value, Color color, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userEmailController.dispose();
    _userFirstNameController.dispose();
    _userLastNameController.dispose();
    _userPasswordController.dispose();
    _movieTitleController.dispose();
    _movieYearController.dispose();
    _movieDescriptionController.dispose();
    _moviePosterUrlController.dispose();
    _movieGenreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading Admin Dashboard...'),
              SizedBox(height: 10),
              Text(
                'Fetching data from Movies collection...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Manager Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              setState(() {
                _showAddUserForm = true;
                _showAddMovieForm = false;
              });
            },
            tooltip: 'Add User',
          ),
          IconButton(
            icon: const Icon(Icons.movie),
            onPressed: () {
              setState(() {
                _showAddMovieForm = true;
                _showAddUserForm = false;
              });
            },
            tooltip: 'Add Movie',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildWelcomeHeader(),
              const SizedBox(height: 24),

              // Quick Stats
              _buildStatsRow(),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Add User Form (if visible)
              if (_showAddUserForm) ...[
                _buildAddUserForm(),
                const SizedBox(height: 24),
              ],

              // Add Movie Form (if visible)
              if (_showAddMovieForm) ...[
                _buildAddMovieForm(),
                const SizedBox(height: 24),
              ],

              // Top Movies Section
              _buildTopMoviesSection(),
              const SizedBox(height: 24),

              // User Management
              _buildUsersSection(),
              const SizedBox(height: 24),

              // System Status
              _buildSystemStatus(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}