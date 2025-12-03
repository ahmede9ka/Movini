import 'package:flutter/material.dart';
import '../../services/movie_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/movie_card.dart';
import '../auth/authService.dart';
import '../details/movie_details_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> with TickerProviderStateMixin {
  final MovieService movieService = MovieService();
  final AuthService authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> movies = [];
  bool isLoading = false;
  bool isSearching = false;
  String currentQuery = "Avengers";
  Set<String> favoriteMovies = {};
  int favoritesCount = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.text = currentQuery;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    search(currentQuery);
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadFavorites() async {
    try {
      final count = await authService.getFavoritesCount();
      final favorites = await authService.getUserFavorites();
      setState(() {
        favoritesCount = count;
        favoriteMovies = Set.from(favorites.map((fav) => fav['movieId']?.toString() ?? ''));
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(String movieId, Map<String, dynamic> movie) async {
    try {
      final isCurrentlyFavorite = await authService.isFavorite(movieId);

      if (isCurrentlyFavorite) {
        final result = await authService.removeFromFavorites(movieId);
        if (result['success'] == true) {
          setState(() {
            favoritesCount--;
            favoriteMovies.remove(movieId);
          });
          _showSnackBar('Removed from favorites', Icons.favorite_border);
        }
      } else {
        final result = await authService.addToFavorites(
          movieId: movieId,
          movieTitle: movie['Title']?.toString() ?? 'Unknown',
          year: movie['Year']?.toString() ?? '',
          posterUrl: (movie['Poster'] != null &&
              movie['Poster'] != 'N/A' &&
              movie['Poster'].toString().isNotEmpty)
              ? movie['Poster'].toString()
              : 'https://via.placeholder.com/300x450.png?text=No+Image',
          rating: movie['imdbRating']?.toString() ?? '0.0',
        );
        if (result['success'] == true) {
          setState(() {
            favoritesCount++;
            favoriteMovies.add(movieId);
          });
          _showSnackBar('Added to favorites', Icons.favorite);
        }
      }
    } catch (e) {
      _showSnackBar('Error updating favorites', Icons.error);
      print('Error toggling favorite: $e');
    }
  }

  void search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      currentQuery = query;
    });

    _fadeController.reset();

    final results = await movieService.searchMovies(query);

    if (mounted) {
      setState(() {
        movies = results;
        isLoading = false;
      });
      _fadeController.forward();
    }
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToDetails(Map<String, dynamic> movie) {
    final movieId = movie['imdbID']?.toString() ?? movie['Title']?.toString() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(
          movieId: movieId,
          title: movie['Title']?.toString() ?? 'Unknown',
          posterUrl: (movie['Poster'] != null &&
              movie['Poster'] != 'N/A' &&
              movie['Poster'].toString().isNotEmpty)
              ? movie['Poster'].toString()
              : 'https://via.placeholder.com/300x450.png?text=No+Image',
          year: movie['Year']?.toString() ?? '',
          rating: movie['imdbRating']?.toString() ?? '0.0',
          isFavorite: favoriteMovies.contains(movieId),
          onToggleFavorite: (movieId) async {
            // Find the movie in the current list
            final movieToToggle = movies.firstWhere(
                  (m) => (m['imdbID']?.toString() ?? m['Title']?.toString()) == movieId,
              orElse: () => {},
            );
            if (movieToToggle.isNotEmpty) {
              await toggleFavorite(movieId, movieToToggle);
            }
          },
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

          // Results header - Only show when not loading and has results
          if (!isLoading && movies.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildResultsHeader(),
              ),
            ),

          // Loading state
          if (isLoading)
            SliverFillRemaining(
              child: _buildLoadingState(),
            )

          // Empty state
          else if (movies.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )

          // Movies grid
          else
            _buildMoviesGrid(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      snap: false,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        centerTitle: false,
        title: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSearching ? 0.0 : 1.0,
          child: const Text(
            'Movies',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).primaryColor.withOpacity(0.6),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildSearchBar(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search movies...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
              size: 24,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.grey[600],
                size: 24,
              ),
              onPressed: () {
                _searchController.clear();
                search("Avengers");
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              search(value);
              _searchFocusNode.unfocus();
            }
          },
          onChanged: (value) {
            setState(() {
              isSearching = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              isSearching = _searchController.text.isNotEmpty;
            });
          },
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Results for "$currentQuery"',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movies.length} movies found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$favoritesCount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(
          height: 1,
          color: Colors.grey,
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
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading movies...',
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 32),
          Text(
            'No movies found',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Try searching for something else',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.text = 'Avengers';
              search('Avengers');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try "Avengers" Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              _searchFocusNode.requestFocus();
            },
            icon: const Icon(Icons.search),
            label: const Text('Search for another movie'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: BorderSide(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final movie = movies[index];
            final movieId = movie['imdbID']?.toString() ?? movie['Title']?.toString() ?? '';

            return FadeTransition(
              opacity: _fadeAnimation,
              child: MovieCard(
                title: movie['Title']?.toString() ?? 'Unknown',
                posterUrl: (movie['Poster'] != null &&
                    movie['Poster'] != 'N/A' &&
                    movie['Poster'].toString().isNotEmpty)
                    ? movie['Poster'].toString()
                    : 'https://via.placeholder.com/300x450.png?text=No+Image',
                year: movie['Year']?.toString(),
                rating: movie['imdbRating']?.toString(),
                isFavorite: favoriteMovies.contains(movieId),
                onFavorite: () => toggleFavorite(movieId, movie),
                onTap: () => _navigateToDetails(movie),
              ),
            );
          },
          childCount: movies.length,
        ),
      ),
    );
  }
}