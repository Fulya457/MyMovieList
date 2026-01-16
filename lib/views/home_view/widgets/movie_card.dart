import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/models/movie_model.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isGrid;

  const MovieCard({super.key, required this.movie, this.isGrid = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movie-detail', extra: movie),
      child: isGrid ? _buildGridCard() : _buildListCard(),
    );
  }

  Widget _buildGridCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Hero(
        tag: 'movie_${movie.id}',
        child: CachedNetworkImage(
          imageUrl: movie.poster,
          fit: BoxFit.cover,
          memCacheWidth: 200,
          placeholder: (context, url) => Container(color: AppTheme.surfaceDark),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Hero(
              tag: 'movie_${movie.id}',
              child: CachedNetworkImage(
                imageUrl: movie.poster,
                width: 70,
                height: 100,
                fit: BoxFit.cover,
                memCacheWidth: 150,
                placeholder: (c, u) => Container(
                  width: 70,
                  height: 100,
                  color: AppTheme.surfaceDark,
                ),
                errorWidget: (c, u, e) =>
                    Container(width: 70, height: 100, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(
                      " ${movie.rating.toStringAsFixed(1)}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  movie.genres.isNotEmpty ? movie.genres.join(', ') : '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
