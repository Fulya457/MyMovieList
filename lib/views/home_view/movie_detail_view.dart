import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Modeller
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/models/person_model.dart';

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
    // HATA KORUMASI: trailerId null gelebilir diye varsayılan boş string atıyoruz
    
    MovieManager.instance.fetchTrailerId(widget.movie).then((_) {
      if (mounted) {
        _controller = YoutubePlayerController(
          // Eğer trailerId boşsa dummy bir id veriyoruz ki çökmesin
          initialVideoId: (widget.movie.trailerId.isNotEmpty)
              ? widget.movie.trailerId
              : 'dQw4w9WgXcQ',
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
    try {
      _controller.dispose();
    } catch (e) {}
    super.dispose();
  }

  // --- YENİ EKLENEN: LİSTE OLUŞTURMA PENCERESİ ---
  void _showCreateListDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Yeni Liste Oluştur", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Liste Adı (örn: İzlenecekler)",
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await MovieManager.instance.createCustomList(
                  nameController.text.trim(),
                  'movies',
                );
                if (mounted) {
                  Navigator.pop(ctx); // Dialogu kapat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Liste başarıyla oluşturuldu!")),
                  );
                  // BottomSheet'i tekrar açabiliriz veya kullanıcı kendi açar
                }
              }
            },
            child: const Text("Oluştur", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  // -----------------------------------------------

  void _showAddToListSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add to List",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.grey),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getUserListsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.playlist_add,
                              size: 50,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Henüz listeniz yok.",
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                // DÜZELTİLDİ: Artık direkt liste oluşturma dialogunu açıyor
                                _showCreateListDialog(context); 
                              },
                              child: const Text(
                                "Liste oluşturmak için tıklayın",
                                style: TextStyle(color: AppTheme.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final listData =
                            docs[index].data() as Map<String, dynamic>;
                        final listId = docs[index].id;
                        final movies =
                            listData['items'] as List? ??
                            listData['movies'] as List? ??
                            [];
                        final bool alreadyAdded = movies.any(
                          (m) => m['id'] == widget.movie.id,
                        );

                        return ListTile(
                          leading: const Icon(Icons.list, color: Colors.white),
                          title: Text(
                            listData['name'] ?? 'İsimsiz',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "${movies.length} films",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check, color: Colors.green)
                              : const Icon(
                                  Icons.add,
                                  color: AppTheme.primaryBlue,
                                ),
                          onTap: () async {
                            if (!alreadyAdded) {
                              await MovieManager.instance.addMovieToCustomList(
                                listId,
                                widget.movie,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${widget.movie.title} listeye eklendi!",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Arkadaşına Öner",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getFriendsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty)
                      return const Center(
                        child: Text(
                          "Arkadaş listesi boş.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final email = data['email'] ?? 'Unknown';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              email.isNotEmpty ? email[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            email,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            MovieManager.instance.sendMessage(
                              receiverUid: data['uid'],
                              text: "Sana bir film önerdim!",
                              sharedMovie: widget.movie,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Film önerildi!")),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
      body: AnimatedBuilder(
        animation: MovieManager.instance,
        builder: (context, child) {
          final isFav = MovieManager.instance.isFavorite(widget.movie);

          return CustomScrollView(
            slivers: [
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
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () =>
                        MovieManager.instance.toggleFavorite(widget.movie),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.playlist_add,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => _showAddToListSheet(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => _showShareBottomSheet(context),
                  ),
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
                      Hero(
                        tag: 'movie_${widget.movie.id}',
                        child: CachedNetworkImage(
                          imageUrl: widget.movie.poster,
                          fit: BoxFit.cover,
                          placeholder: (c, u) =>
                              Container(color: AppTheme.surfaceDark),
                          errorWidget: (c, o, s) =>
                              Container(color: Colors.grey),
                        ),
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
                      Wrap(
                        spacing: 8,
                        children: widget.movie.genres
                            .map(
                              (genre) => InkWell(
                                onTap: () => context.pushNamed(
                                  AppRouters.genreMovies,
                                  pathParameters: {'genre': genre},
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    genre,
                                    style: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Release Date:",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            widget.movie.releaseDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TMDB Rating:",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 22,
                              ),
                              Text(
                                " ${widget.movie.rating.toStringAsFixed(1)} / 10",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      StreamBuilder<DocumentSnapshot>(
                        stream: MovieManager.instance.getMovieLiveRating(
                          widget.movie.id,
                        ),
                        builder: (context, snapshot) {
                          double liveRating = 0.0;
                          int liveCount = 0;
                          bool hasData = false;
                          if (snapshot.hasData &&
                              snapshot.data != null &&
                              snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            liveRating = (data['app_rating'] ?? 0.0).toDouble();
                            liveCount = (data['vote_count'] ?? 0).toInt();
                            hasData = true;
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "User Rate :",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (hasData && liveCount > 0)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.lightBlueAccent,
                                          size: 22,
                                        ),
                                        Text(
                                          " ${liveRating.toStringAsFixed(1)} / 10",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          " ($liveCount)",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    const Text(
                                      "No ratings yet",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: MovieManager.instance.getReviewsStream(
                                  widget.movie.id,
                                ),
                                builder: (context, revSnap) {
                                  if (!revSnap.hasData) return const SizedBox();
                                  List<String> friendRatings = [];
                                  for (var doc in revSnap.data!.docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    if (MovieManager.instance.isFriend(
                                      data['user_id'],
                                    ))
                                      friendRatings.add(
                                        "${data['user_name'] ?? 'Arkadaş'} ${(data['rating'] as num).toStringAsFixed(1)} verdi",
                                      );
                                  }
                                  if (friendRatings.isEmpty)
                                    return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "(${friendRatings.join(', ')})",
                                      style: const TextStyle(
                                        color: Colors.lightGreenAccent,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      Text(
                        "Director: ${widget.movie.director}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
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

                      // --- OYUNCULAR (CAST) ---
                      const Text(
                        "Cast",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (widget.movie.castDetails.isEmpty &&
                          widget.movie.director == "Loading...")
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      else
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.movie.castDetails.isNotEmpty
                                ? widget.movie.castDetails.length
                                : widget.movie.actors.length,
                            itemBuilder: (context, index) {
                              if (widget.movie.castDetails.isNotEmpty) {
                                final actor = widget.movie.castDetails[index];
                                final photoUrl = actor['photo'] ?? '';
                                final actorName = actor['name'] ?? 'Unknown';

                                return Padding(
                                  padding: const EdgeInsets.only(right: 15.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (actor['id'] != null) {
                                        final person = Person(
                                          id:
                                              int.tryParse(
                                                actor['id'].toString(),
                                              ) ??
                                              0,
                                          name: actorName,
                                          profilePath: photoUrl,
                                          knownFor: 'Acting',
                                        );
                                        context.push(
                                          '/person-detail',
                                          extra: person,
                                        );
                                      }
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: (photoUrl.length > 5)
                                                ? CachedNetworkImage(
                                                    imageUrl: photoUrl,
                                                    fit: BoxFit.cover,
                                                    placeholder: (c, u) =>
                                                        Container(
                                                          color: Colors.grey,
                                                        ),
                                                    errorWidget: (c, u, e) =>
                                                        Container(
                                                          color: Colors.grey,
                                                          child: const Icon(
                                                            Icons.person,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                  )
                                                : Container(
                                                    color: Colors.grey,
                                                    child: const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            actorName,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
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
                              }
                            },
                          ),
                        ),
                      // ---------------------------------------------------
                      const SizedBox(height: 20),
                      if ((widget.movie.trailerId.isNotEmpty) &&
                          widget.movie.trailerId != 'dQw4w9WgXcQ')
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: RepaintBoundary(
                            child: YoutubePlayer(
                              controller: _controller,
                              showVideoProgressIndicator: true,
                            ),
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
              StreamBuilder<QuerySnapshot>(
                stream: MovieManager.instance.getReviewsStream(widget.movie.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty)
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
          );
        },
      ),
    );
  }
}

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
      text: widget.doc['comment'] ?? '',
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
              setState(() => showReplies = true);
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
    final int iconId = data['profile_icon_id'] ?? 0;
    final safeIndex =
        (iconId >= 0 && iconId < MovieManager.instance.profileIcons.length)
        ? iconId
        : 0;
    final String iconUrl = MovieManager.instance.profileIcons[safeIndex];

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(iconUrl),
                    ),
                    const SizedBox(width: 8),
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
            Text(
              data['comment'] ?? '',
              style: const TextStyle(color: Colors.white),
            ),
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
