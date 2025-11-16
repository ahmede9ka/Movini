import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // temporary placeholder data
    final favorites = [
      {"title": "Interstellar", "poster": "https://picsum.photos/200/301"},
      {"title": "Inception", "poster": "https://picsum.photos/200/302"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("My Favorites")),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  favorites[index]["poster"]!,
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                favorites[index]["title"]!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Icon(Icons.delete, color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
