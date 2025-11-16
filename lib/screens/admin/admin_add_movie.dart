import 'package:flutter/material.dart';

class AdminAddMovie extends StatelessWidget {
  const AdminAddMovie({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController imageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Movie')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add your logic to save movie
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Movie Added!')),
                );
              },
              child: const Text('Add Movie'),
            ),
          ],
        ),
      ),
    );
  }
}
