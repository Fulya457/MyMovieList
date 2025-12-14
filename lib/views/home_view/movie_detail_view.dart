import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/review_service.dart';
import 'package:mymovielist/views/home_view/actor_detail_view.dart';
import 'package:mymovielist/views/list_view/list_view.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MovieDetailView extends StatefulWidget {
  final Movie movie;
  const MovieDetailView({super.key, required this.movie});

  @override
  State<MovieDetailView> createState() => _MovieDetailViewState();
}

class _MovieDetailViewState extends State<MovieDetailView> {
  late YoutubePlayerController _controller;
  final ReviewService _reviewService = ReviewService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.movie.trailerId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        forceHD: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateAverage(List<DocumentSnapshot> docs) {
    if (docs.isEmpty) return 0.0;
    double total = 0;
    for (var doc in docs) {
      total += (doc['rating'] as num).toDouble();
    }
    return total / docs.length;
  }

  void _showReviewModal(
    BuildContext context, {
    DocumentSnapshot? existingReview,
  }) {
    final TextEditingController commentController = TextEditingController(
      text: existingReview?['comment'] ?? "",
    );
    double selectedRating = existingReview != null
        ? (existingReview['rating'] as num).toDouble()
        : 5.0;
    bool isEditing = existingReview != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? "Edit Review" : "Rate & Review",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            10,
                            (index) => Icon(
                              index < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${selectedRating.toInt()} / 10",
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Slider(
                          value: selectedRating,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: AppTheme.primaryBlue,
                          inactiveColor: Colors.grey,
                          onChanged: (val) =>
                              setModalState(() => selectedRating = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write your thoughts...",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          if (isEditing) {
                            _reviewService.updateReview(
                              widget.movie.id,
                              existingReview!.id,
                              commentController.text,
                              selectedRating,
                            );
                          } else {
                            _reviewService.addReview(
                              widget.movie.id,
                              commentController.text,
                              selectedRating,
                            );
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        isEditing ? "Update Review" : "Submit Review",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRepliesModal(
    BuildContext context,
    String reviewId,
    String parentComment,
  ) {
    final TextEditingController replyController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Replying to: \"$parentComment\"",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Replies",
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _reviewService.getReplies(widget.movie.id, reviewId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                      return const Center(
                        child: Text(
                          "No replies yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final reply = snapshot.data!.docs[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey,
                            child: Text(
                              reply['userName'][0],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          title: Text(
                            reply['userName'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            reply['text'],
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Add a reply...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF222222),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.primaryBlue),
                      onPressed: () {
                        if (replyController.text.isNotEmpty) {
                          _reviewService.addReply(
                            widget.movie.id,
                            reviewId,
                            replyController.text,
                          );
                          replyController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppTheme.primaryBlue,
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            title: Text(widget.movie.title),
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: AppTheme.primaryBlue),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showReviewModal(context),
            backgroundColor: AppTheme.primaryBlue,
            icon: const Icon(Icons.rate_review, color: Colors.white),
            label: const Text(
              "Rate Movie",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.black,
                  child: widget.movie.trailerId.isNotEmpty
                      ? player
                      : const SizedBox(height: 200),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'poster_${widget.movie.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.movie.poster,
                                width: 100,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.movie.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "IMDb: ${widget.movie.rating}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                StreamBuilder<QuerySnapshot>(
                                  stream: _reviewService.getReviews(
                                    widget.movie.id,
                                  ),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData)
                                      return const Text(
                                        "Loading...",
                                        style: TextStyle(color: Colors.grey),
                                      );
                                    final docs = snapshot.data!.docs;
                                    final avg = _calculateAverage(docs);
                                    return Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          docs.isEmpty
                                              ? "No User Rating"
                                              : "User: ${avg.toStringAsFixed(1)} (${docs.length} votes)",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        children: widget.movie.genres
                            .map(
                              (genre) => ActionChip(
                                label: Text(genre),
                                backgroundColor: const Color(0xFF333333),
                                labelStyle: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                ),
                                side: BorderSide.none,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GenreMoviesView(genre: genre),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Plot",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.movie.plot,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Cast",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.movie.actors.length,
                          itemBuilder: (context, index) {
                            final actorName = widget.movie.actors[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ActorDetailView(actorName: actorName),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333333),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Center(
                                  child: Text(
                                    actorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Divider(color: Colors.grey),
                      const Text(
                        "Community Reviews",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

                      StreamBuilder<QuerySnapshot>(
                        stream: _reviewService.getReviews(widget.movie.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  "No reviews yet. Be the first!",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              List<dynamic> likes = data.containsKey('likes')
                                  ? data['likes']
                                  : [];
                              final bool isLiked = likes.contains(
                                currentUserId,
                              );
                              final bool isMyReview =
                                  data['userId'] == currentUserId;
                              final bool isEdited =
                                  data.containsKey('isEdited') &&
                                  data['isEdited'] == true;
                              // YANIT SAYISI
                              final int replyCount =
                                  data.containsKey('replyCount')
                                  ? data['replyCount']
                                  : 0;

                              return Card(
                                color: const Color(0xFF1E1E1E),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: isMyReview
                                                ? AppTheme.primaryBlue
                                                : Colors.grey,
                                            radius: 12,
                                            child: Text(
                                              data['userName'][0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            data['userName'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isEdited)
                                            const Text(
                                              " (edited)",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 10,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          Text(
                                            " ${data['rating']}",
                                            style: const TextStyle(
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        data['comment'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () =>
                                                _reviewService.toggleLike(
                                                  widget.movie.id,
                                                  doc.id,
                                                  likes,
                                                ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isLiked
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: isLiked
                                                      ? Colors.red
                                                      : Colors.grey,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${likes.length}",
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          GestureDetector(
                                            onTap: () => _showRepliesModal(
                                              context,
                                              doc.id,
                                              data['comment'],
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.chat_bubble_outline,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Reply",
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                // --- YENİ: YANIT SAYACI GÖSTERGESİ ---
                                                if (replyCount > 0)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          left: 6,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blueGrey,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "$replyCount",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          if (isMyReview)
                                            GestureDetector(
                                              onTap: () => _showReviewModal(
                                                context,
                                                existingReview: doc,
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit,
                                                    color: AppTheme.primaryBlue,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Edit",
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme.primaryBlue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
