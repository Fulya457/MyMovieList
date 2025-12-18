import 'package:mymovielist/models/movie_model.dart';

const String TMDB_PROFILE_BASE_URL = "https://image.tmdb.org/t/p/w200";

class Person {
  final int id;
  final String name;
  final String profilePath;
  final String knownFor;
  String biography;
  String birthday;
  String placeOfBirth;
  List<Movie> filmography;

  Person({
    required this.id,
    required this.name,
    required this.profilePath,
    required this.knownFor,
    this.biography = "",
    this.birthday = "",
    this.placeOfBirth = "",
    this.filmography = const [],
  });

  factory Person.fromTMDB(Map<String, dynamic> json) {
    return Person(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      profilePath: json['profile_path'] != null
          ? TMDB_PROFILE_BASE_URL + json['profile_path']
          : "",
      knownFor: json['known_for_department'] ?? 'Acting',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profile_path': profilePath,
      'known_for_department': knownFor,
    };
  }
}
