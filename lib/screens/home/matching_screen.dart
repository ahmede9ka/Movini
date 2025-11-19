import 'package:flutter/material.dart';
import 'dart:math' as math;

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Temporary list until Firebase logic added
  final matchedUsers = [
    {
      "name": "Ahmed",
      "match": 92,
      "photo": "https://picsum.photos/200/200?random=1",
      "commonMovies": 12,
      "favoriteGenre": "Action",
      "lastActive": "2 hours ago"
    },
    {
      "name": "Ines",
      "match": 88,
      "photo": "https://picsum.photos/200/200?random=2",
      "commonMovies": 8,
      "favoriteGenre": "Drama",
      "lastActive": "Online"
    },
    {
      "name": "Omar",
      "match": 85,
      "photo": "https://picsum.photos/200/200?random=3",
      "commonMovies": 15,
      "favoriteGenre": "Sci-Fi",
      "lastActive": "1 day ago"
    },
    {
      "name": "Salma",
      "match": 79,
      "photo": "https://picsum.photos/200/200?random=4",
      "commonMovies": 6,
      "favoriteGenre": "Comedy",
      "lastActive": "5 hours ago"
    },
    {
      "name": "Youssef",
      "match": 76,
      "photo": "https://picsum.photos/200/200?random=5",
      "commonMovies": 10,
      "favoriteGenre": "Thriller",
      "lastActive": "Online"
    },
  ];

  Color _getMatchColor(int match) {
    if (match >= 90) return Colors.green[600]!;
    if (match >= 80) return Colors.lightGreen[600]!;
    if (match >= 70) return Colors.orange[600]!;
    return Colors.grey[600]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Matches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.purple[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${matchedUsers.length} matches',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildMatchesList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      backgroundColor: Colors.purple[700],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Movie Matches',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple[700]!,
                    Colors.purple[600]!,
                    Colors.deepPurple[600]!,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.deepPurple[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.favorite,
            value: '${matchedUsers.length}',
            label: 'Total Matches',
            color: Colors.red[600]!,
          ),
          Container(width: 1, height: 50, color: Colors.purple[200]),
          _buildStatItem(
            icon: Icons.star_rounded,
            value: '${matchedUsers.where((u) => (u['match'] as int) >= 80).length}',
            label: 'High Matches',
            color: Colors.amber[700]!,
          ),
          Container(width: 1, height: 50, color: Colors.purple[200]),
          _buildStatItem(
            icon: Icons.trending_up,
            value: '${matchedUsers.isNotEmpty ? matchedUsers.map((u) => u['match'] as int).reduce((a, b) => a + b) ~/ matchedUsers.length : 0}%',
            label: 'Avg Match',
            color: Colors.green[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMatchesList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final user = matchedUsers[index];

            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index / matchedUsers.length).clamp(0.0, 1.0),
                    1.0,
                    curve: Curves.easeOut,
                  ),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index / matchedUsers.length).clamp(0.0, 1.0),
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: _buildMatchCard(user, index),
              ),
            );
          },
          childCount: matchedUsers.length,
        ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> user, int index) {
    final match = user['match'] as int;
    final matchColor = _getMatchColor(match);
    final isOnline = user['lastActive'] == 'Online';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('View ${user['name']}\'s profile'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: matchColor.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(user['photo'] as String),
                        radius: 35,
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green[500],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['name'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Match percentage badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: matchColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 14,
                                  color: matchColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$match%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: matchColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Common movies & genre
                      Row(
                        children: [
                          Icon(Icons.movie, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${user['commonMovies']} movies in common',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Loves ${user['favoriteGenre']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Last active
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: isOnline ? Colors.green[600] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user['lastActive'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.green[600] : Colors.grey[500],
                              fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action button
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Start chat with ${user['name']}'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.chat_bubble,
                    color: Colors.purple[600],
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.purple[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}