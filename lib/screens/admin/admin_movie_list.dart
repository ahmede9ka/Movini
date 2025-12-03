// lib/screens/admin/admin_movie_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMovieList extends StatefulWidget {
  const AdminMovieList({super.key});

  @override
  State<AdminMovieList> createState() => _AdminMovieListState();
}

class _AdminMovieListState extends State<AdminMovieList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _movies = [];
  List<Map<String, dynamic>> _filteredMovies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Most Viewed', 'Highest Rated', 'Recently Added'];

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final query = await _firestore
          .collection('Movies')
          .orderBy('createdAt', descending: true)
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
        _movies = movies;
        _filteredMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading movies: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _movies;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((movie) {
        final title = (movie['title'] ?? '').toLowerCase();
        final description = (movie['description'] ?? '').toLowerCase();
        final genre = (movie['genre'] is List
            ? (movie['genre'] as List).join(' ').toLowerCase()
            : '').toLowerCase();
        return title.contains(_searchQuery.toLowerCase()) ||
            description.contains(_searchQuery.toLowerCase()) ||
            genre.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting filter
    switch (_selectedFilter) {
      case 'Most Viewed':
        filtered.sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
        break;
      case 'Highest Rated':
        filtered.sort((a, b) => (b['rating'] ?? 0.0).compareTo(a['rating'] ?? 0.0));
        break;
      case 'Recently Added':
        filtered.sort((a, b) {
          final aDate = a['createdAt'] as DateTime? ?? DateTime(2000);
          final bDate = b['createdAt'] as DateTime? ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
    }

    setState(() {
      _filteredMovies = filtered;
    });
  }

  void _showDeleteDialog(String movieId, String movieTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Movie'),
        content: Text('Are you sure you want to delete "$movieTitle"? This will remove it from the Movies collection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMovie(movieId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMovie(String movieId) async {
    try {
      // Delete from Movies collection
      await _firestore.collection('Movies').doc(movieId).delete();

      // Also delete from all users' favorites
      try {
        final users = await _firestore.collection('users').get();
        for (final userDoc in users.docs) {
          await _firestore
              .collection('favorites')
              .doc(userDoc.id)
              .collection('Movies')
              .doc(movieId)
              .delete();
        }
      } catch (e) {
        // Ignore if favorites don't exist
      }

      // Remove from local list
      setState(() {
        _movies.removeWhere((movie) => movie['id'] == movieId);
        _filteredMovies.removeWhere((movie) => movie['id'] == movieId);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movie deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting movie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMovieDetails(Map<String, dynamic> movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(movie['title'] ?? 'Movie Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poster
              if (movie['posterUrl'] != null && movie['posterUrl'].isNotEmpty)
                Center(
                  child: Container(
                    width: 200,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(movie['posterUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    width: 200,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.movie, size: 80, color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 20),

              // Movie Info
              _buildDetailRow('Title', movie['title'] ?? 'No title'),
              _buildDetailRow('Year', movie['year']?.toString() ?? ''),
              _buildDetailRow('Rating', '${movie['rating'] ?? 0.0} ⭐'),
              _buildDetailRow('Views', '${movie['views'] ?? 0} 👁️'),

              if (movie['genre'] is List && (movie['genre'] as List).isNotEmpty)
                _buildDetailRow('Genres', (movie['genre'] as List).join(', ')),

              if ((movie['description'] ?? '').isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie['description'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),

              if (movie['createdAt'] != null)
                _buildDetailRow('Added', _formatDate(movie['createdAt'] as DateTime)),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showMovieDetails(movie);
        },
        child: ListTile(
          leading: Container(
            width: 60,
            height: 80,
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
                ? const Icon(Icons.movie, size: 30, color: Colors.grey)
                : null,
          ),
          title: Text(
            movie['title'] ?? 'No title',
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${movie['year'] ?? ''} • ${movie['genre'] is List ? (movie['genre'] as List).take(2).join(', ') : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${movie['views'] ?? 0}'),
                  const SizedBox(width: 12),
                  Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${movie['rating'] ?? 0.0}'),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.info, size: 20),
                    SizedBox(width: 8),
                    Text('Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'details') {
                _showMovieDetails(movie);
              } else if (value == 'edit') {
                _showEditMovieDialog(movie);
              } else if (value == 'delete') {
                _showDeleteDialog(movie['id'], movie['title']);
              }
            },
          ),
        ),
      ),
    );
  }

  void _showEditMovieDialog(Map<String, dynamic> movie) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit functionality for "${movie['title']}" will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAddMovieDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Movie'),
        content: const Text('To add a new movie, please use the "Add Movie" button in the Admin Dashboard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Movies Collection',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_movies.length} movies',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Live',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMovieDialog,
            tooltip: 'Add Movie',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMovies,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStatsHeader(),
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search movies by title, description, or genre...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          selectedColor: Colors.blue.shade100,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              _applyFilters();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Movies List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMovies.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_filter,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No movies found for "$_searchQuery"'
                        : 'No movies found in Movies collection',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                      child: const Text('Clear search'),
                    ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadMovies,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredMovies.length,
                itemBuilder: (context, index) {
                  return _buildMovieCard(_filteredMovies[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}