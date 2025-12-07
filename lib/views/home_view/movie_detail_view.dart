import 'package:flutter/material.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MovieDetailView extends StatefulWidget {
  final Movie movie;

  const MovieDetailView({super.key, required this.movie});

  @override
  State<MovieDetailView> createState() => _MovieDetailViewState();
}

class _MovieDetailViewState extends State<MovieDetailView> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Youtube ID'si ile oynatıcıyı başlatıyoruz
    _controller = YoutubePlayerController(
      initialVideoId: widget.movie.trailerId, 
      flags: const YoutubePlayerFlags(
        autoPlay: false, // Sayfa açılınca otomatik başlamasın
        mute: false,
        disableDragSeek: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Sayfadan çıkınca videoyu kapat
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack, // Arka plan TAM SİYAH
      appBar: AppBar(
        title: Text(widget.movie.title),
        backgroundColor: Colors.transparent, // AppBar transparan olsun
        iconTheme: const IconThemeData(color: AppTheme.primaryBlue), // Geri tuşu Mavi
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- YOUTUBE VİDEO OYNATICI ---
            Container(
              color: Colors.black,
              child: widget.movie.trailerId.isNotEmpty 
                ? YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                    // İlerleme çubuğu rengi: NEON MAVİ
                    progressIndicatorColor: AppTheme.primaryBlue,
                    progressColors: const ProgressBarColors(
                      playedColor: AppTheme.primaryBlue,
                      handleColor: Colors.blueAccent,
                    ),
                  )
                : const SizedBox(
                    height: 200, 
                    child: Center(child: Text("No Trailer Available", style: TextStyle(color: Colors.white)))
                  ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BAŞLIK VE PUAN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.movie.title,
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white // Yazı Beyaz
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.primaryBlue), // Yıldız Mavi
                          const SizedBox(width: 5),
                          Text(
                            widget.movie.rating.toString(),
                            style: const TextStyle(
                              fontSize: 18, 
                              color: Colors.white, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // --- KATEGORİ ETİKETLERİ (GENRES) ---
                  Wrap(
                    spacing: 8,
                    children: widget.movie.genres.map((genre) => Chip(
                      label: Text(genre),
                      // Etiket Kutusu: Koyu Gri, Yazı: Mavi
                      backgroundColor: const Color(0xFF333333), 
                      labelStyle: const TextStyle(color: AppTheme.primaryBlue),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  // --- KONU (PLOT) ---
                  const Text("Plot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.plot, 
                    style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 16)
                  ),
                  
                  const SizedBox(height: 20),

                  // --- OYUNCULAR (CAST) ---
                  const Text("Cast", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.movie.actors.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            // Oyuncu Kutusu: Koyu Gri
                            color: const Color(0xFF333333), 
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              widget.movie.actors[index],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}