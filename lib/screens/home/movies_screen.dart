import 'package:flutter/material.dart';
import '../../widgets/movie_card.dart';

class MoviesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Temporary list until we integrate API
    final movies = [
      {"title": "Interstellar", "poster": "https://picsum.photos/200/300"},
      {"title": "Inception", "poster": "https://picsum.photos/201/300"},
      {"title": "Tenet", "poster": "https://picsum.photos/202/300"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Movies")),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        itemCount: movies.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        itemBuilder: (context, index) {
          return MovieCard(
            title: movies[index]["title"]!,
            posterUrl: movies[index]["poster"]!,
            onFavorite: () {
              // later Firebase
            },
          );
        },
      ),
    );
  }
}
