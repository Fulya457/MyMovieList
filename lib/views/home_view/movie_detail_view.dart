// Dosya: lib/views/home_view/movie_detail_view.dart

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

    MovieManager.instance.fetchTrailerId(widget.movie).then((_) {
      if (mounted) {
        _controller = YoutubePlayerController(
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

  // --- YÖNETMENE GİTME FONKSİYONU ---
  void _navigateToDirector() async {
    final directorName = widget.movie.director;
    if (directorName == "Unknown" || directorName == "Loading...") return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Director profile loading...")),
    );

    await MovieManager.instance.searchMovies(directorName);

    if (mounted) {
      final results = MovieManager.instance.searchResults;
      final director = results.firstWhere(
        (item) => item is Person,
        orElse: () => null,
      );

      if (director != null) {
        context.push('/person-detail', extra: director as Person);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Director profile can not be found.")),
        );
      }
    }
  }

  // --- LİSTE OLUŞTURMA PENCERESİ ---
  void _showCreateListDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          "Create New List",
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                hintText: "List Name",
                hintStyle: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await MovieManager.instance.createCustomList(
                  nameController.text.trim(),
                  'movies',
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("List is created sucsessfully!"),
                    ),
                  );
                }
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddToListSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack, // Dinamik Arkaplan
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add to list",
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // --- HER ZAMAN GÖZÜKEN OLUŞTURMA BUTONU ---
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: AppTheme.primaryBlue),
                ),
                title: Text(
                  "Create New List",
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateListDialog(context);
                },
              ),
              Divider(color: AppTheme.textColor.withValues(alpha: 0.2)),

              // --- MEVCUT LİSTELER ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getUserListsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;

                    final movieLists = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['type'] == 'movies' ||
                          data['type'] == 'movie' ||
                          data['type'] == null;
                    }).toList();

                    if (movieLists.isEmpty) {
                      return Center(
                        child: Text(
                          "You have no list yet.",
                          style: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: movieLists.length,
                      itemBuilder: (context, index) {
                        final listData =
                            movieLists[index].data() as Map<String, dynamic>;
                        final listId = movieLists[index].id;
                        final movies =
                            listData['items'] as List? ??
                            listData['movies'] as List? ??
                            [];
                        final bool alreadyAdded = movies.any(
                          (m) => m['id'] == widget.movie.id,
                        );

                        return ListTile(
                          leading: Icon(Icons.list, color: AppTheme.iconColor),
                          title: Text(
                            listData['name'] ?? 'Untitled',
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                          subtitle: Text(
                            "${movies.length} film",
                            style: TextStyle(
                              color: AppTheme.textColor.withValues(alpha: 0.6),
                            ),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check, color: Colors.green)
                              : Icon(Icons.add, color: AppTheme.primaryBlue),
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
                                      "${widget.movie.title} added!",
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
              Text(
                "Arkadaşına Öner",
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getFriendsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          "Arkadaş listesi boş.",
                          style: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

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
                            style: TextStyle(color: AppTheme.textColor),
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
              title: Text(
                'Rate & Review',
                style: TextStyle(color: AppTheme.textColor),
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
                      style: TextStyle(color: AppTheme.textColor),
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
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Yorum eklendi!")),
                      );
                    }
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
                expandedHeight: 400.0, // Daha büyük poster alanı
                pinned: true,
                backgroundColor: AppTheme.backgroundBlack,
                leading: IconButton(
                  // Poster üzerindeki butonlar her zaman beyaz kalsın
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white,
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
                      // Play butonu (Trailer varsa)
                      if (widget.movie.trailerId.isNotEmpty)
                        Center(
                          child: IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white70,
                              size: 70,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.black,
                                  contentPadding: EdgeInsets.zero,
                                  content: _controller.value.isReady
                                      ? YoutubePlayer(
                                          controller: _controller,
                                          showVideoProgressIndicator: true,
                                        )
                                      : const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Text(
                                              "Fragman yükleniyor...",
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // --- İÇERİK KISMI ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor, // DİNAMİK RENK
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.movie.genres
                            .map(
                              (genre) => InkWell(
                                onTap: () => context.push('/list/${genre}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    genre,
                                    style: TextStyle(
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
                          Text(
                            "Release Date:",
                            style: TextStyle(
                              color: AppTheme.textColor.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.movie.releaseDate,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        color: AppTheme.textColor.withValues(alpha: 0.2),
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "TMDB Rating:",
                            style: TextStyle(
                              color: AppTheme.textColor.withValues(alpha: 0.6),
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
                                style: TextStyle(
                                  color: AppTheme.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(
                        color: AppTheme.textColor.withValues(alpha: 0.2),
                        height: 20,
                      ),

                      // Canlı Kullanıcı Puanı
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
                                  Text(
                                    "User Rate :",
                                    style: TextStyle(
                                      color: AppTheme.textColor.withValues(
                                        alpha: 0.6,
                                      ),
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
                                          style: TextStyle(
                                            color: AppTheme.textColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          " ($liveCount)",
                                          style: TextStyle(
                                            color: AppTheme.textColor
                                                .withValues(alpha: 0.6),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      "No ratings yet",
                                      style: TextStyle(
                                        color: AppTheme.textColor.withValues(
                                          alpha: 0.5,
                                        ),
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
                                    )) {
                                      friendRatings.add(
                                        "${data['user_name'] ?? 'Arkadaş'} ${(data['rating'] as num).toStringAsFixed(1)} verdi",
                                      );
                                    }
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
                      InkWell(
                        onTap: _navigateToDirector,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Director: ",
                                style: TextStyle(
                                  color: AppTheme.textColor.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: widget.movie.director,
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Plot",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      Text(
                        widget.movie.plot,
                        style: TextStyle(
                          color: AppTheme.textColor.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Cast",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (widget.movie.castDetails.isEmpty &&
                          widget.movie.director == "Loading...")
                        Center(
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
                                                color: Colors.black.withValues(
                                                  alpha: 0.5,
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
                                            style: TextStyle(
                                              color: AppTheme.textColor
                                                  .withValues(alpha: 0.7),
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
                                // Fallback (Detay yoksa)
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
                                        style: TextStyle(
                                          color: AppTheme.textColor.withValues(
                                            alpha: 0.7,
                                          ),
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
                      const SizedBox(height: 20),

                      // FRAGMAN (Trailer)
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

                      // REVIEWS BAŞLIĞI
                      Divider(color: AppTheme.textColor.withValues(alpha: 0.2)),
                      Text(
                        "User Reviews",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // YORUM LİSTESİ
              StreamBuilder<QuerySnapshot>(
                stream: MovieManager.instance.getReviewsStream(widget.movie.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty)
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "Henüz yorum yok. İlk sen ol!",
                          style: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.5),
                          ),
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
        title: Text(
          "Yorumu Düzenle",
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: TextField(
          controller: editController,
          style: TextStyle(color: AppTheme.textColor),
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
        title: Text("Yanıtla", style: TextStyle(color: AppTheme.textColor)),
        content: TextField(
          controller: replyController,
          style: TextStyle(color: AppTheme.textColor),
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
                      style: TextStyle(
                        color: AppTheme.textColor.withValues(alpha: 0.7),
                      ),
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
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['comment'] ?? '',
              style: TextStyle(color: AppTheme.textColor),
            ),
            if (data['is_edited'] == true)
              Text(
                "(düzenlendi)",
                style: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.5),
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
                    style: TextStyle(color: AppTheme.primaryBlue),
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
                    return Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        "Henüz yanıt yok.",
                        style: TextStyle(
                          color: AppTheme.textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
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
                            color: AppTheme.textColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rData['user_name'] ?? 'User',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                rData['text'] ?? '',
                                style: TextStyle(
                                  color: AppTheme.textColor.withValues(
                                    alpha: 0.8,
                                  ),
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
