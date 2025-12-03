// lib/screens/admin/admin_stats.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_firebase_service.dart';

class AdminStats extends StatefulWidget {
  const AdminStats({super.key});

  @override
  State<AdminStats> createState() => _AdminStatsState();
}

class _AdminStatsState extends State<AdminStats> {
  final AdminFirebaseService _adminService = AdminFirebaseService();
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topMovies = [];
  List<Map<String, dynamic>> _topUsers = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Last 30 days';
  final List<String> _periods = ['Last 7 days', 'Last 30 days', 'Last 90 days', 'This year'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load dashboard stats
      final stats = await _adminService.getDashboardStats();

      // Load top movies by views
      final movies = await _adminService.getAllMovies();
      movies.sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));

      // Load active users
      final users = await _adminService.getAllUsers();
      users.sort((a, b) {
        final aDate = a['lastLogin'] as DateTime? ?? DateTime(2000);
        final bDate = b['lastLogin'] as DateTime? ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _stats = stats;
        _topMovies = movies.take(5).toList();
        _topUsers = users.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard(String title, dynamic value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value.toString(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopMoviesList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Movies by Views',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_topMovies.isEmpty)
              const Center(child: Text('No movies found'))
            else
              ..._topMovies.map((movie) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: movie['posterUrl'] != null && movie['posterUrl'].isNotEmpty
                      ? NetworkImage(movie['posterUrl'])
                      : null,
                  child: movie['posterUrl'] == null || movie['posterUrl'].isEmpty
                      ? const Icon(Icons.movie, color: Colors.grey)
                      : null,
                ),
                title: Text(movie['title'] ?? 'No title'),
                subtitle: Text('${movie['year'] ?? ''} • ${movie['views'] ?? 0} views'),
                trailing: Chip(
                  label: Text('${movie['rating'] ?? 0.0}'),
                  backgroundColor: Colors.amber[100],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUsersList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Active Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_topUsers.isEmpty)
              const Center(child: Text('No users found'))
            else
              ..._topUsers.map((user) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user['photoURL'] != null && user['photoURL'].isNotEmpty
                      ? NetworkImage(user['photoURL'])
                      : null,
                  child: user['photoURL'] == null || user['photoURL'].isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                title: Text(user['name'] ?? 'No name'),
                subtitle: Text(user['email'] ?? 'No email'),
                trailing: Chip(
                  label: Text(user['role'] ?? 'user'),
                  backgroundColor: user['role'] == 'admin' ? Colors.green[100] : Colors.blue[100],
                ),
              )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              Row(
                children: [
                  const Text(
                    'Time Period:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                      _loadStats();
                    },
                    items: _periods.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard('Total Movies', _stats['totalMovies'] ?? 0, Icons.movie, Colors.blue),
                  _buildStatCard('Total Users', _stats['totalUsers'] ?? 0, Icons.people, Colors.green),
                  _buildStatCard("Today's Views", _stats['todaysViews'] ?? 0, Icons.visibility, Colors.orange),
                  _buildStatCard('Total Favorites', _stats['totalFavorites'] ?? 0, Icons.favorite, Colors.red),
                  _buildStatCard('Active Users', _stats['activeUsers'] ?? 0, Icons.person_add, Colors.purple),
                  _buildStatCard('Revenue', '\$${_stats['revenue'] ?? 0}', Icons.attach_money, Colors.teal),
                ],
              ),
              const SizedBox(height: 32),

              // Top Movies
              _buildTopMoviesList(),
              const SizedBox(height: 24),

              // Top Users
              _buildTopUsersList(),
              const SizedBox(height: 24),

              // Activity Chart (Placeholder)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Activity chart will be implemented here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
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