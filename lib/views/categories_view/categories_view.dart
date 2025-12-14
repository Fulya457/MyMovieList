import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/data/genre_service.dart'; // Poster URL'lerini çekmek için

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    // MovieManager'dan gelen tür isimlerini çekiyoruz
    final allGenres = MovieManager.instance.allGenreNames;

    // GenreService'i dinleyerek poster URL'lerinin yüklenmesini bekliyoruz
    return ListenableBuilder(
      listenable: Listenable.merge([
        GenreService.instance,
        MovieManager.instance, // <-- Bu satırı ekleyin/kontrol edin
      ]),
      builder: (context, child) {
        final allGenres = MovieManager.instance.allGenreNames;
        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            title: const Text(
              'Film Kategorileri',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppTheme.backgroundBlack,
          ),
          body: allGenres.isEmpty
              ? const Center(
                  child: Text(
                    'Kategori yüklenemedi.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: allGenres.length,
                  itemBuilder: (context, index) {
                    final genreName = allGenres[index];

                    return GenreCard(
                      genreName: genreName,
                      onTap: () {
                        // Geri butonu için PUSH kullanıyoruz
                        context.push('${AppRouters.list}/$genreName');
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

// --- KATEGORİ KARTI WIDGET'I ---

class GenreCard extends StatelessWidget {
  final String genreName;
  final VoidCallback onTap;

  const GenreCard({super.key, required this.genreName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Poster URL'sini GenreService'ten dinamik olarak çekiyoruz
    final imageUrl = GenreService.instance.genrePosterUrls[genreName];

    // Eğer görsel yüklenmemişse veya hala yükleniyorsa
    Widget imageWidget = imageUrl != null
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppTheme.surfaceDark,
              ); // Yüklenirken koyu arka plan
            },
            errorBuilder: (c, o, s) =>
                Container(color: Colors.red.withOpacity(0.5)),
          )
        : Container(
            color: AppTheme.surfaceDark,
          ); // Poster URL'si yoksa veya yükleniyorsa

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Arka Plan Resmi/Placeholder
            imageWidget,

            // Geçiş Efekti (Overlay)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Kategori Adı
            Positioned(
              bottom: 10,
              left: 10,
              child: Text(
                genreName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
