import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- 1. YORUM EKLEME (Sayacı 0 olarak başlatıyoruz) ---
  Future<void> addReview(int movieId, String comment, double rating) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .add({
          'userId': user.uid,
          'userName': user.displayName ?? user.email!.split('@')[0],
          'comment': comment,
          'rating': rating,
          'likes': [],
          'replyCount': 0, // <--- YENİ: Başlangıçta 0 yanıt
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // --- 2. YORUM GÜNCELLEME ---
  Future<void> updateReview(
    int movieId,
    String reviewId,
    String newComment,
    double newRating,
  ) async {
    await _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .doc(reviewId)
        .update({'comment': newComment, 'rating': newRating, 'isEdited': true});
  }

  // --- 3. BEĞENİ (LIKE) ---
  Future<void> toggleLike(
    int movieId,
    String reviewId,
    List<dynamic> currentLikes,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final reviewRef = _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .doc(reviewId);

    if (currentLikes.contains(user.uid)) {
      await reviewRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await reviewRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  // --- 4. YANIT EKLEME (Ana yorumdaki sayacı artırıyoruz) ---
  Future<void> addReply(int movieId, String reviewId, String replyText) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Yanıtı ekle
    await _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .doc(reviewId)
        .collection('replies')
        .add({
          'userId': user.uid,
          'userName': user.displayName ?? user.email!.split('@')[0],
          'text': replyText,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // 2. Ana yorumdaki sayacı 1 artır (Increment)
    await _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .doc(reviewId)
        .update({'replyCount': FieldValue.increment(1)});
  }

  // --- VERİ ÇEKME ---
  Stream<QuerySnapshot> getReviews(int movieId) {
    return _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getReplies(int movieId, String reviewId) {
    return _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .doc(reviewId)
        .collection('replies')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // --- YENİ: FİLMİN ORTALAMA SARI PUANINI ÇEKME ---
  // (Recommended sayfası için gerekli)
  Future<double> getMovieUserRating(int movieId) async {
    final query = await _db
        .collection('movies')
        .doc(movieId.toString())
        .collection('reviews')
        .get();
    if (query.docs.isEmpty) return 0.0;

    double total = 0;
    for (var doc in query.docs) {
      total += (doc['rating'] as num).toDouble();
    }
    return total / query.docs.length;
  }
}
