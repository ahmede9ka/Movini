import 'package:flutter/material.dart';

class MovieCard extends StatelessWidget {
  final String title;
  final String posterUrl;
  final VoidCallback onFavorite;

  MovieCard({
    required this.title,
    required this.posterUrl,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.network(
              posterUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IconButton(
              onPressed: onFavorite,
              icon: Icon(Icons.favorite_border),
            ),
          )
        ],
      ),
    );
  }
}
