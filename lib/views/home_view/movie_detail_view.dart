import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MovieDetailView extends StatefulWidget {
  final Movie movie;
  const MovieDetailView({super.key, required this.movie});

  @override
  State<MovieDetailView> createState() => _MovieDetailViewState();
}

class _MovieDetailViewState extends State<MovieDetailView> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    MovieManager.instance.fetchCast(widget.movie);
    MovieManager.instance.fetchTrailerId(widget.movie).then((_) {
      if (mounted) {
        _controller = YoutubePlayerController(
          initialVideoId: widget.movie.trailerId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        )..addListener(_listener);
        setState(() {});
      }
    });
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- PUAN VE YORUM EKLEME DİYALOĞU ---
  void _showRatingDialog() {
    final TextEditingController reviewController = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text(
                'Rate & Review',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rating.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.star, color: Colors.amber, size: 28),
                      ],
                    ),
                    Slider(
                      value: rating,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (value) => setState(() => rating = value),
                    ),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Yorumunu yaz...",
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                  onPressed: () async {
                    if (reviewController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    await MovieManager.instance.addReview(
                      widget.movie,
                      rating,
                      reviewController.text.trim(),
                    );
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Yorum eklendi!")),
                      );
                  },
                  child: const Text(
                    'Gönder',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: CustomScrollView(
        slivers: [
          // 1. APP BAR & POSTER
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: AppTheme.backgroundBlack,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.rate_review,
                  color: Colors.amber,
                  size: 28,
                ),
                onPressed: _showRatingDialog,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.movie.poster,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(color: Colors.grey),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.backgroundBlack.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. FİLM DETAYLARI (SliverToBoxAdapter içinde)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.movie.genres.isNotEmpty
                          ? widget.movie.genres.first
                          : 'Genre',
                      style: const TextStyle(color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 22),
                      Text(
                        " ${widget.movie.rating.toStringAsFixed(1)} / 10 (TMDB)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (widget.movie.appRating != null &&
                      widget.movie.appRating! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.lightBlueAccent,
                            size: 22,
                          ),
                          Text(
                            " ${widget.movie.appRating!.toStringAsFixed(1)} / 10 ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "(${widget.movie.appVoteCount} votes)",
                            style: const TextStyle(
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    "Director: ${widget.movie.director}",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Plot",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.movie.plot,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Cast",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.movie.actors.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.movie.actors[index],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.movie.trailerId.isNotEmpty &&
                      widget.movie.trailerId != 'dQw4w9WgXcQ')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: YoutubePlayer(
                        controller: _controller,
                        showVideoProgressIndicator: true,
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey),
                  const Text(
                    "User Reviews",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // 3. YORUMLAR (BUĞA GİRMEMESİ İÇİN SLIVER LIST KULLANIYORUZ)
          StreamBuilder<QuerySnapshot>(
            stream: MovieManager.instance.getReviewsStream(widget.movie.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "Henüz yorum yok. İlk sen ol!",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final doc = docs[index];
                  return ReviewCard(doc: doc);
                }, childCount: docs.length),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 50)),
        ],
      ),
    );
  }
}

// --- GELİŞMİŞ YORUM KARTI WIDGET'I ---
class ReviewCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const ReviewCard({super.key, required this.doc});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool showReplies = false;

  void _editReview() {
    final TextEditingController editController = TextEditingController(
      text: widget.doc['comment'],
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          "Yorumu Düzenle",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await MovieManager.instance.editReview(
                widget.doc.id,
                editController.text.trim(),
                (widget.doc['rating'] as num).toDouble(),
              );
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _replyToReview() {
    final TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Yanıtla", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: replyController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Cevabın..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await MovieManager.instance.replyToReview(
                widget.doc.id,
                replyController.text.trim(),
              );
              if (mounted) Navigator.pop(ctx);
              setState(() => showReplies = true); // Otomatik aç
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == data['user_id'];
    final likes = (data['likes'] as List?) ?? [];
    final isLiked = likes.contains(currentUid);
    final Timestamp? ts = data['timestamp'];
    final dateStr = ts != null
        ? DateFormat('dd MMM yyyy').format(ts.toDate())
        : '';

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Kısım: İsim, Puan ve Menü
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      data['user_name'] ?? 'User',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(
                      " ${data['rating']}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                if (isOwner)
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') _editReview();
                      if (value == 'delete')
                        MovieManager.instance.deleteReview(widget.doc.id);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text("Düzenle"),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text("Sil", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),

            Text(
              dateStr,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
            const SizedBox(height: 8),
            Text(data['comment'], style: const TextStyle(color: Colors.white)),
            if (data['is_edited'] == true)
              const Text(
                "(düzenlendi)",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 10),

            // Alt Butonlar: Beğen, Yanıtla
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () =>
                      MovieManager.instance.toggleLikeReview(widget.doc.id),
                ),
                Text(
                  "${likes.length}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 15),
                TextButton.icon(
                  icon: const Icon(Icons.reply, size: 18, color: Colors.grey),
                  label: const Text(
                    "Yanıtla",
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: _replyToReview,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => showReplies = !showReplies),
                  child: Text(
                    showReplies ? "Cevapları Gizle" : "Cevapları Gör",
                    style: const TextStyle(color: AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),

            // Yanıtlar Bölümü (Expandable)
            if (showReplies)
              StreamBuilder<QuerySnapshot>(
                stream: MovieManager.instance.getRepliesStream(widget.doc.id),
                builder: (context, snapshot) {
                  final replies = snapshot.data?.docs ?? [];
                  if (replies.isEmpty)
                    return const Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Text(
                        "Henüz yanıt yok.",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );

                  return Padding(
                    padding: const EdgeInsets.only(left: 20, top: 5),
                    child: Column(
                      children: replies.map((r) {
                        final rData = r.data() as Map<String, dynamic>;
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rData['user_name'] ?? 'User',
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                rData['text'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
