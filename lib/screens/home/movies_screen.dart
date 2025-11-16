import 'package:flutter/material.dart';
import '../../services/movie_services.dart';
import '../../widgets/movie_card.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final MovieService movieService = MovieService();
  List movies = [];
  bool isLoading = false;

  void search(String query) async {
    setState(() => isLoading = true);
    final results = await movieService.searchMovies(query);
    setState(() {
      movies = results;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    search("Avengers"); // default search
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movies")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cards per row
          childAspectRatio: 0.65, // adjust for poster + title + button
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return MovieCard(
            title: movie['Title'],
            posterUrl: movie['Poster'] != 'N/A'
                ? movie['Poster']
                : 'https://via.placeholder.com/200x300.png?text=No+Image',
            onFavorite: () {
              // handle favorite logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${movie['Title']} added to favorites')),
              );
            },
          );
        },
      ),
    );
  }
}
