import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieService {
  final String apiKey = "440fc3d6"; // replace with your key

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final url = Uri.parse("https://www.omdbapi.com/?s=$query&apikey=$apiKey");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['Response'] == "True") {
        // return list of movies
        return List<Map<String, dynamic>>.from(data['Search']);
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load movies');
    }
  }
}
