import 'package:flutter/material.dart';

class AdminUsers extends StatelessWidget {
  const AdminUsers({super.key});

  @override
  Widget build(BuildContext context) {
    // Example static users
    final users = ['Alice', 'Bob', 'Charlie'];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(users[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Delete logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${users[index]} deleted!')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
