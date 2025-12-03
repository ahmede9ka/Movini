import 'package:flutter/material.dart';
import 'movies_screen.dart';
import '../favorites/favorites_screen.dart';
import 'matching_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const MoviesScreen(),
      const FavoritesScreen(),
      const MatchingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.movie_outlined, 0),
              activeIcon: _buildNavIcon(Icons.movie, 0),
              label: "Movies",
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.favorite_border, 1),
              activeIcon: _buildNavIcon(Icons.favorite, 1),
              label: "Favorites",
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.people_outline, 2),
              activeIcon: _buildNavIcon(Icons.people, 2),
              label: "Matching",
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outline, 3),
              activeIcon: _buildNavIcon(Icons.person, 3),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int itemIndex) {
    final isSelected = index == itemIndex;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 24),
    );
  }
}