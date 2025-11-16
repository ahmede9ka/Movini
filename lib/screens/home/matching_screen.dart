import 'package:flutter/material.dart';

class MatchingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Temporary list until Firebase logic added
    final matchedUsers = [
      {"name": "Ahmed", "match": 82, "photo": "https://picsum.photos/50"},
      {"name": "Ines", "match": 91, "photo": "https://picsum.photos/51"},
      {"name": "Omar", "match": 76, "photo": "https://picsum.photos/52"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Your Matches")),
      body: ListView.builder(
        padding: EdgeInsets.all(15),
        itemCount: matchedUsers.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  matchedUsers[index]["photo"]?.toString() ?? "",
                ),
                radius: 28,
              ),
              title: Text(
                matchedUsers[index]["name"]?.toString() ?? "",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Match: ${matchedUsers[index]["match"]}%",
                style: TextStyle(color: Colors.green),
              ),
            ),
          );
        },
      ),
    );
  }
}
