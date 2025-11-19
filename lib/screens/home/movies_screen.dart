import 'package:flutter/material.dart';
import '../../services/movie_services.dart';
import '../../widgets/movie_card.dart';
import '../details/movie_details_screen.dart';

class MoviesScreen extends StatefulWidget {
  final Set<String> favoriteMovies;
  final Function(String) onFavoriteToggle;

  const MoviesScreen({
    super.key,
    required this.favoriteMovies,
    required this.onFavoriteToggle,
  });

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> with TickerProviderStateMixin {
  final MovieService movieService = MovieService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List movies = [];
  bool isLoading = false;
  bool isSearching = false;
  String currentQuery = "Avengers";

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      currentQuery = query;
    });

    _fadeController.reset();

    final results = await movieService.searchMovies(query);

    setState(() {
      movies = results;
      isLoading = false;
    });

    _fadeController.forward();
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

  void _navigateToDetails(Map movie) {
    final movieId = movie['imdbID'] ?? movie['Title'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(
          movieId: movieId,
          title: movie['Title'] ?? 'Unknown',
          posterUrl: movie['Poster'] != 'N/A' && movie['Poster'] != null
              ? movie['Poster']
              : 'https://via.placeholder.com/300x450.png?text=No+Image',
          isFavorite: widget.favoriteMovies.contains(movieId),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultsHeader(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          isLoading
              ? SliverFillRemaining(child: _buildLoadingState())
              : movies.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : _buildMoviesGrid(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: !isSearching
            ? const Text(
          'Movies',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        )
            : null,
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildSearchBar(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Hero(
      tag: 'search_bar',
      child: Material(
        color: Colors.transparent,
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
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                onPressed: () {
                  _searchController.clear();
                  search("Avengers");
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                search(value);
                _searchFocusNode.unfocus();
              }
            },
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Results for "$currentQuery"',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${movies.length} movies found',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.favorite, size: 16, color: Theme.of(context).primaryColor),
              const SizedBox(width: 6),
              Text(
                '${widget.favoriteMovies.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
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
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading movies...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text('No movies found', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 12),
          Text('Try searching for something else', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.text = 'Avengers';
              search('Avengers');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Search'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesGrid() {
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
            final movie = movies[index];
            final movieId = movie['imdbID'] ?? movie['Title'];

            return FadeTransition(
              opacity: _fadeAnimation,
              child: MovieCard(
                title: movie['Title'] ?? 'Unknown',
                posterUrl: movie['Poster'] != 'N/A' && movie['Poster'] != null
                    ? movie['Poster']
                    : 'https://via.placeholder.com/300x450.png?text=No+Image',
                year: movie['Year'],
                rating: movie['imdbRating'],
                isFavorite: widget.favoriteMovies.contains(movieId),
                onFavorite: () {
                  widget.onFavoriteToggle(movieId);
                  _showSnackBar(
                    widget.favoriteMovies.contains(movieId) ? 'Added to favorites' : 'Removed from favorites',
                    widget.favoriteMovies.contains(movieId) ? Icons.favorite : Icons.favorite_border,
                  );
                },
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