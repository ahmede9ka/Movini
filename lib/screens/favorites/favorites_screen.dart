import 'package:flutter/material.dart';
import '../../services/movie_services.dart';
import '../../widgets/movie_card.dart';
import '../details/movie_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final Set<String> favoriteMovies;
  final Function(String) onFavoriteToggle;

  const FavoritesScreen({
    super.key,
    required this.favoriteMovies,
    required this.onFavoriteToggle,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  final MovieService movieService = MovieService();
  Map<String, Map<String, dynamic>> favoriteMoviesDetails = {};
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadFavoriteMovies();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.favoriteMovies.length != oldWidget.favoriteMovies.length) {
      _loadFavoriteMovies();
    }
  }

  Future<void> _loadFavoriteMovies() async {
    setState(() => isLoading = true);

    Map<String, Map<String, dynamic>> details = {};

    for (String movieId in widget.favoriteMovies) {
      try {
        final movieDetails = await movieService.getMovieDetails(movieId);
        details[movieId] = movieDetails;
      } catch (e) {
        // Skip movies that fail to load
      }
    }

    setState(() {
      favoriteMoviesDetails = details;
      isLoading = false;
    });

    _animationController.forward(from: 0);
  }

  void _navigateToDetails(Map movie, String movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(
          movieId: movieId,
          title: movie['Title'] ?? 'Unknown',
          posterUrl: movie['Poster'] != 'N/A' && movie['Poster'] != null
              ? movie['Poster']
              : 'https://via.placeholder.com/300x450.png?text=No+Image',
          isFavorite: true,
          onToggleFavorite: widget.onFavoriteToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),

          if (isLoading)
            SliverFillRemaining(child: _buildLoadingState())
          else if (widget.favoriteMovies.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else ...[
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
                            'Your Collection',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${favoriteMoviesDetails.length} movies',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildFavoritesGrid(),
            ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      backgroundColor: Colors.red[700],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'My Favorites',
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
                    Colors.red[700]!,
                    Colors.red[600]!,
                    Colors.pink[600]!,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 150,
                height: 150,
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
    final genres = <String, int>{};
    int totalRating = 0;
    int ratedMovies = 0;

    for (var movie in favoriteMoviesDetails.values) {
      // Count genres
      final genreStr = movie['Genre'] as String?;
      if (genreStr != null && genreStr != 'N/A') {
        for (var genre in genreStr.split(',')) {
          final trimmed = genre.trim();
          genres[trimmed] = (genres[trimmed] ?? 0) + 1;
        }
      }

      // Average rating
      final rating = movie['imdbRating'] as String?;
      if (rating != null && rating != 'N/A') {
        try {
          totalRating += (double.parse(rating) * 10).toInt();
          ratedMovies++;
        } catch (e) {}
      }
    }

    final topGenre = genres.entries.isEmpty
        ? 'Various'
        : genres.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final avgRating = ratedMovies > 0
        ? (totalRating / ratedMovies / 10).toStringAsFixed(1)
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[50]!, Colors.pink[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.local_movies_rounded,
              value: '${favoriteMoviesDetails.length}',
              label: 'Movies',
              color: Colors.red[700]!,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.red[200]),
          Expanded(
            child: _buildStatItem(
              icon: Icons.category_rounded,
              value: topGenre,
              label: 'Top Genre',
              color: Colors.pink[700]!,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.red[200]),
          Expanded(
            child: _buildStatItem(
              icon: Icons.star_rounded,
              value: avgRating,
              label: 'Avg Rating',
              color: Colors.amber[700]!,
            ),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red[700]!),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your favorites...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[50]!, Colors.pink[50]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Movies you love will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[50]!, Colors.pink[50]!],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'How to add favorites',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTipRow(Icons.search, 'Search for movies'),
                  const SizedBox(height: 8),
                  _buildTipRow(Icons.favorite_border, 'Tap the heart icon'),
                  const SizedBox(height: 8),
                  _buildTipRow(Icons.star, 'Build your collection'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesGrid() {
    final moviesList = favoriteMoviesDetails.entries.toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final entry = moviesList[index];
            final movieId = entry.key;
            final movie = entry.value;

            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index / moviesList.length).clamp(0.0, 1.0),
                    1.0,
                    curve: Curves.easeOut,
                  ),
                ),
              ),
              child: MovieCard(
                title: movie['Title'] ?? 'Unknown',
                posterUrl: movie['Poster'] != 'N/A' && movie['Poster'] != null
                    ? movie['Poster']
                    : 'https://via.placeholder.com/300x450.png?text=No+Image',
                year: movie['Year'],
                rating: movie['imdbRating'],
                isFavorite: true,
                onFavorite: () {
                  widget.onFavoriteToggle(movieId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.favorite_border, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Removed from favorites'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                onTap: () => _navigateToDetails(movie, movieId),
              ),
            );
          },
          childCount: moviesList.length,
        ),
      ),
    );
  }
}