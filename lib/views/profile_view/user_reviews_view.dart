import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class UserReviewsView extends StatelessWidget {
  const UserReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("You must log in.")));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          "My reviews",
          style: TextStyle(color: AppTheme.primaryBlue),
        ),
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('user_id', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "An error occurred during loading.",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "You haven't commented yet.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String comment = data['comment'] ?? '';
              final double rating = (data['rating'] ?? 0).toDouble();
              final String movieTitle = data['movie_title'] ?? 'Film';
              final String posterPath = data['poster_path'] ?? '';
              final int movieId = data['movie_id'] ?? 0;
              final Timestamp? ts = data['timestamp'];
              final dateStr = ts != null
                  ? DateFormat('dd MMM yyyy').format(ts.toDate())
                  : '';

              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () async {
                    if (movieId != 0) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (c) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      final movie = await MovieManager.instance.getMovieById(
                        movieId,
                      );
                      if (context.mounted) Navigator.pop(context);
                      if (movie != null && context.mounted) {
                        context.push('/movie-detail', extra: movie);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // POSTER (Küçük)
                        if (posterPath.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              posterPath,
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => Container(
                                width: 60,
                                height: 90,
                                color: Colors.grey,
                              ),
                            ),
                          ),

                        const SizedBox(width: 12),

                        // İÇERİK
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movieTitle,
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  Text(
                                    " $rating",
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24),
                              Text(
                                comment,
                                style: TextStyle(color: AppTheme.primaryBlue),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
