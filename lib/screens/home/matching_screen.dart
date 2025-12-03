import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/authService.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> matchedUsers = [];
  bool isLoading = true;
  Map<String, dynamic> currentUserData = {};
  List<String> currentUserFavorites = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadUserDataAndMatches();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDataAndMatches() async {
    setState(() => isLoading = true);

    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        setState(() {
          isLoading = false;
          matchedUsers = [];
        });
        return;
      }

      // Load current user data
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        currentUserData = userDoc.data()!;
      }

      // Load current user's favorites
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .doc(currentUserId)
          .collection('movies')
          .get();

      currentUserFavorites = favoritesSnapshot.docs.map((doc) => doc.id).toList();

      // Load all other users
      final allUsersSnapshot = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> allUsers = allUsersSnapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => {
        'id': doc.id,
        ...doc.data()!,
        'favorites': [], // Will be populated
        'matchPercentage': 0,
        'commonMovies': 0,
      })
          .toList();

      // For each user, load their favorites and calculate match
      for (var user in allUsers) {
        try {
          final userFavoritesSnapshot = await _firestore
              .collection('favorites')
              .doc(user['id'])
              .collection('movies')
              .get();

          final userFavorites = userFavoritesSnapshot.docs.map((doc) => doc.id).toList();
          user['favorites'] = userFavorites;

          // Calculate common movies
          final commonMovies = _calculateCommonMovies(currentUserFavorites, userFavorites);
          user['commonMovies'] = commonMovies;

          // Calculate match percentage
          user['matchPercentage'] = _calculateMatchPercentage(
              currentUserFavorites,
              userFavorites,
              commonMovies
          );

          // Get favorite genre
          user['favoriteGenre'] = await _getFavoriteGenre(user['id']);

          // Get last active (simplified - using timestamp)
          user['lastActive'] = _getLastActiveText(user['lastActive'] ?? '');

        } catch (e) {
          print('Error loading user ${user['id']} favorites: $e');
        }
      }

      // Filter and sort users by match percentage
      matchedUsers = allUsers
          .where((user) => user['matchPercentage'] > 0)
          .toList()
        ..sort((a, b) => b['matchPercentage'].compareTo(a['matchPercentage']));

      setState(() => isLoading = false);
      _animationController.forward();

    } catch (e) {
      print('Error loading matches: $e');
      setState(() {
        isLoading = false;
        matchedUsers = [];
      });
    }
  }

  int _calculateCommonMovies(List<String> user1Favorites, List<String> user2Favorites) {
    if (user1Favorites.isEmpty || user2Favorites.isEmpty) return 0;

    final set1 = user1Favorites.toSet();
    final set2 = user2Favorites.toSet();
    return set1.intersection(set2).length;
  }

  int _calculateMatchPercentage(
      List<String> user1Favorites,
      List<String> user2Favorites,
      int commonMovies
      ) {
    if (user1Favorites.isEmpty || user2Favorites.isEmpty) return 0;

    final totalUniqueMovies = {...user1Favorites, ...user2Favorites}.length;
    if (totalUniqueMovies == 0) return 0;

    // Calculate percentage based on common movies
    final percentage = (commonMovies / totalUniqueMovies * 100).toInt();
    return percentage.clamp(0, 100);
  }

  Future<String> _getFavoriteGenre(String userId) async {
    try {
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('movies')
          .get();

      // Count genres
      final genreCount = <String, int>{};

      for (var doc in favoritesSnapshot.docs) {
        final movieData = doc.data();
        final genre = movieData['genre'] as String?;
        if (genre != null && genre.isNotEmpty && genre != 'N/A' && genre != 'Unknown') {
          final genres = genre.split(',');
          for (var g in genres) {
            final trimmed = g.trim();
            genreCount[trimmed] = (genreCount[trimmed] ?? 0) + 1;
          }
        }
      }

      if (genreCount.isEmpty) return 'Various';

      final topGenre = genreCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      return topGenre;
    } catch (e) {
      return 'Various';
    }
  }

  String _getLastActiveText(String timestamp) {
    // This is a simplified version. You should store last active timestamp in Firestore
    // For now, we'll use random values
    final options = ['Online', '2 hours ago', '1 day ago', '5 hours ago', 'Just now'];
    return options[DateTime.now().millisecondsSinceEpoch % options.length];
  }

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
          isLoading ? _buildLoadingState() : _buildMatchesList(),
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
    final highMatches = matchedUsers.where((u) => u['matchPercentage'] >= 80).length;
    final avgMatch = matchedUsers.isNotEmpty
        ? matchedUsers.map((u) => u['matchPercentage'] as int).reduce((a, b) => a + b) ~/ matchedUsers.length
        : 0;

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
            value: '$highMatches',
            label: 'High Matches',
            color: Colors.amber[700]!,
          ),
          Container(width: 1, height: 50, color: Colors.purple[200]),
          _buildStatItem(
            icon: Icons.trending_up,
            value: '$avgMatch%',
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

  Widget _buildLoadingState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[700]!),
            ),
            const SizedBox(height: 24),
            Text(
              'Finding your movie matches...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    if (matchedUsers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[50]!, Colors.deepPurple[50]!],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.purple[300],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'No matches yet',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add more movies to your favorites to find people with similar taste',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadUserDataAndMatches,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Matches'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
    final match = user['matchPercentage'] as int;
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
            _showUserProfile(user);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
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
                        backgroundImage: NetworkImage(
                            user['photoURL']?.toString().isNotEmpty == true
                                ? user['photoURL'].toString()
                                : 'https://ui-avatars.com/api/?name=${user['prenom']}+${user['nom']}&background=6d28d9&color=fff'
                        ),
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

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user['prenom'] ?? ''} ${user['nom'] ?? 'User'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
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

                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _startChatWithUser(user);
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

  void _showUserProfile(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user['prenom']} ${user['nom']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                  user['photoURL']?.toString().isNotEmpty == true
                      ? user['photoURL'].toString()
                      : 'https://ui-avatars.com/api/?name=${user['prenom']}+${user['nom']}&background=6d28d9&color=fff'
              ),
              radius: 40,
            ),
            const SizedBox(height: 16),
            Text('Match: ${user['matchPercentage']}%'),
            Text('Common Movies: ${user['commonMovies']}'),
            Text('Favorite Genre: ${user['favoriteGenre']}'),
            Text('Email: ${user['email'] ?? 'Not available'}'),
          ],
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

  void _startChatWithUser(Map<String, dynamic> user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting chat with ${user['prenom']} ${user['nom']}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}