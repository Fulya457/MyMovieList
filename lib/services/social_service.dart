import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/models/person_model.dart';

class SocialService {
  static final SocialService instance = SocialService._privateConstructor();
  SocialService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;

  // --- KULLANICI İŞLEMLERİ ---
  Future<void> ensureUserExists() async {
    if (currentUid == null) return;
    final doc = await _firestore.collection('users').doc(currentUid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(currentUid).set({
        'uid': currentUid,
        'email': currentEmail?.toLowerCase(),
        'created_at': FieldValue.serverTimestamp(),
        'favorites_movies': [],
        'profile_icon_id': 0,
      });
    }
  }

  Future<void> updateProfileIcon(int iconIndex) async {
    if (currentUid == null) return;
    await _firestore.collection('users').doc(currentUid).update({
      'profile_icon_id': iconIndex,
    });
  }

  Stream<int> getUserIconIndexStream() {
    if (currentUid == null) return const Stream.empty();
    return _firestore.collection('users').doc(currentUid).snapshots().map((
      doc,
    ) {
      return doc.exists && doc.data()!.containsKey('profile_icon_id')
          ? doc.data()!['profile_icon_id'] as int
          : 0;
    });
  }

  Future<void> changePassword(String newPassword) async {
    await currentUser?.updatePassword(newPassword);
  }

  Future<List<Map<String, dynamic>>> searchUsersByEmail(
    String emailQuery,
  ) async {
    final query = emailQuery.toLowerCase().trim();
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: query)
        .get();
    List<Map<String, dynamic>> users = [];
    for (var doc in snapshot.docs) {
      if (doc.id == currentUid) continue;
      users.add({'uid': doc.id, 'email': doc.data()['email']});
    }
    return users;
  }

  // --- FAVORİLER ---
  Future<void> updateFavoriteMovie(Movie movie, bool isAdding) async {
    if (currentUid == null) return;
    if (isAdding) {
      await _firestore.collection('users').doc(currentUid).update({
        'favorites_movies': FieldValue.arrayUnion([movie.toMap()]),
      });
    } else {
      await _firestore.collection('users').doc(currentUid).update({
        'favorites_movies': FieldValue.arrayRemove([movie.toMap()]),
      });
    }
  }

  Future<void> updateFavoritePerson(Person person, bool isAdding) async {
    if (currentUid == null) return;
    bool isDirector = person.knownFor == 'Directing';
    String fieldName = isDirector ? 'favorites_directors' : 'favorites_actors';

    if (isAdding) {
      await _firestore.collection('users').doc(currentUid).update({
        fieldName: FieldValue.arrayUnion([person.toMap()]),
      });
    } else {
      await _firestore.collection('users').doc(currentUid).update({
        fieldName: FieldValue.arrayRemove([person.toMap()]),
      });
    }
  }

  Future<Map<String, dynamic>> fetchAllFavorites() async {
    if (currentUid == null) return {};
    try {
      final doc = await _firestore.collection('users').doc(currentUid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
    } catch (e) {
      print("Fav Fetch Error: $e");
    }
    return {};
  }

  // --- LİSTELER (GÜNCELLENEN KISIM BURASI) ---

  Future<void> createList(String name, String type) async {
    if (currentUid == null) return;
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('lists')
        .add({
          'name': name,
          'type': type,
          'created_at': FieldValue.serverTimestamp(),
          'items': [],
        });
  }

  // GÜNCELLENDİ: Duplicate kontrolü eklendi
  Future<void> addToList(String listId, Map<String, dynamic> itemData) async {
    if (currentUid == null) return;

    // 1. Mevcut listeyi çek
    final docRef = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('lists')
        .doc(listId);
    final docSnapshot = await docRef.get();

    // 2. Kontrol et
    if (docSnapshot.exists) {
      List currentItems = docSnapshot.data()?['items'] ?? [];
      // ID kontrolü: Eğer listede bu ID varsa işlemi durdur
      bool alreadyExists = currentItems.any(
        (item) => item['id'] == itemData['id'],
      );
      if (alreadyExists) {
        print("Bu öğe zaten listede var.");
        return;
      }
    }

    // 3. Yoksa ekle
    await docRef.update({
      'items': FieldValue.arrayUnion([itemData]),
    });
  }

  Future<void> removeFromList(
    String listId,
    Map<String, dynamic> itemData,
  ) async {
    if (currentUid == null) return;
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('lists')
        .doc(listId)
        .update({
          'items': FieldValue.arrayRemove([itemData]),
          'movies': FieldValue.arrayRemove([itemData]), // Eski veriler için
        });
  }

  Future<void> deleteList(String listId) async {
    if (currentUid == null) return;
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('lists')
        .doc(listId)
        .delete();
  }

  Stream<QuerySnapshot> getUserListsStream() {
    if (currentUid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(currentUid)
        .collection('lists')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // --- ARKADAŞLIK ---
  Future<void> sendFriendRequest(String targetUid, String targetEmail) async {
    if (currentUid == null) return;
    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('friend_requests')
        .doc(currentUid)
        .set({
          'from_uid': currentUid,
          'email': currentEmail,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<void> acceptFriendRequest(
    String requesterUid,
    String requesterEmail,
  ) async {
    if (currentUid == null) return;
    final batch = _firestore.batch();
    batch.set(
      _firestore
          .collection('users')
          .doc(requesterUid)
          .collection('friends')
          .doc(currentUid),
      {
        'uid': currentUid,
        'email': currentEmail,
        'since': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _firestore
          .collection('users')
          .doc(currentUid)
          .collection('friends')
          .doc(requesterUid),
      {
        'uid': requesterUid,
        'email': requesterEmail,
        'since': FieldValue.serverTimestamp(),
      },
    );
    batch.delete(
      _firestore
          .collection('users')
          .doc(currentUid)
          .collection('friend_requests')
          .doc(requesterUid),
    );
    await batch.commit();
  }

  Future<void> removeFriend(String friendUid) async {
    if (currentUid == null) return;
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .doc(friendUid)
        .delete();
    await _firestore
        .collection('users')
        .doc(friendUid)
        .collection('friends')
        .doc(currentUid)
        .delete();

    final chatId = _getChatId(currentUid!, friendUid);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final msgs = await chatRef.collection('messages').get();
    for (var m in msgs.docs) await m.reference.delete();
    await chatRef.delete();
  }

  Stream<QuerySnapshot> getFriendsStream() {
    if (currentUid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .snapshots();
  }

  Stream<QuerySnapshot> getFriendRequestsStream() {
    if (currentUid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friend_requests')
        .snapshots();
  }

  // --- CHAT ---
  String _getChatId(String userA, String userB) =>
      userA.compareTo(userB) < 0 ? "${userA}_$userB" : "${userB}_$userA";

  Future<void> sendMessage(
    String receiverUid,
    String text, {
    Movie? sharedMovie,
    Map<String, dynamic>? sharedList,
  }) async {
    if (currentUid == null) return;
    final chatId = _getChatId(currentUid!, receiverUid);
    Map<String, dynamic> data = {
      'sender_id': currentUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    };
    if (sharedMovie != null) {
      data['movie_id'] = sharedMovie.id;
      data['movie_title'] = sharedMovie.title;
      data['poster_path'] = sharedMovie.poster;
    }
    if (sharedList != null) {
      data['list_id'] = sharedList['id'];
      data['list_name'] = sharedList['name'];
      data['list_count'] = sharedList['count'];
    }
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(data);
  }

  Stream<QuerySnapshot> getMessagesStream(String receiverUid) {
    if (currentUid == null) return const Stream.empty();
    final chatId = _getChatId(currentUid!, receiverUid);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // --- YENİ EKLENEN: BAŞKASININ LİSTESİNİ KOPYALAMA ---
  Future<void> importListFromUser(
    String listName,
    List<dynamic> items,
    String type,
  ) async {
    if (currentUid == null) return;
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('lists')
        .add({
          'name': "$listName (Kopya)",
          'type': type,
          'created_at': FieldValue.serverTimestamp(),
          'items': items,
        });
  }

  Future<List<dynamic>> fetchListItems(String userId, String listId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(listId)
          .get();
      if (doc.exists) {
        return doc.data()?['items'] ?? [];
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  // --- YORUMLAR VE BİLDİRİMLER ---
  Stream<DocumentSnapshot> getMovieLiveRating(int movieId) =>
      _firestore.collection('app_movies').doc(movieId.toString()).snapshots();
  Stream<QuerySnapshot> getReviewsStream(int movieId) => _firestore
      .collection('reviews')
      .where('movie_id', isEqualTo: movieId)
      .snapshots();
  Stream<QuerySnapshot> getRepliesStream(String reviewId) => _firestore
      .collection('reviews')
      .doc(reviewId)
      .collection('replies')
      .orderBy('timestamp')
      .snapshots();

  Future<void> addReview(Movie movie, double rating, String comment) async {
    if (currentUid == null) return;
    final userName = currentEmail?.split('@')[0] ?? 'User';
    final userDoc = await _firestore.collection('users').doc(currentUid).get();
    int iconId =
        (userDoc.exists && userDoc.data()!.containsKey('profile_icon_id'))
        ? userDoc.data()!['profile_icon_id']
        : 0;

    final prev = await _firestore
        .collection('reviews')
        .where('movie_id', isEqualTo: movie.id)
        .where('user_id', isEqualTo: currentUid)
        .get();
    double oldRating = 0.0;
    bool hasRated = false;

    if (prev.docs.isNotEmpty) {
      hasRated = true;
      oldRating = (prev.docs.first.data()['rating'] ?? 0).toDouble();
      final batch = _firestore.batch();
      for (var d in prev.docs)
        batch.update(d.reference, {
          'rating': rating,
          'profile_icon_id': iconId,
        });
      await batch.commit();
    }

    await _firestore.collection('reviews').add({
      'movie_id': movie.id,
      'movie_title': movie.title,
      'poster_path': movie.poster,
      'user_id': currentUid,
      'user_name': userName,
      'profile_icon_id': iconId,
      'rating': rating,
      'comment': comment,
      'likes': [],
      'timestamp': FieldValue.serverTimestamp(),
    });

    final movieRef = _firestore
        .collection('app_movies')
        .doc(movie.id.toString());
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(movieRef);
      if (!snap.exists) {
        tx.set(movieRef, {
          'id': movie.id,
          'title': movie.title,
          'poster_path': movie.poster,
          'vote_sum': rating,
          'vote_count': 1,
          'app_rating': rating,
        });
      } else {
        double sum = (snap.data()!['vote_sum'] ?? 0).toDouble();
        int count = (snap.data()!['vote_count'] ?? 0).toInt();
        if (hasRated) {
          sum = sum - oldRating + rating;
        } else {
          sum += rating;
          count += 1;
        }
        tx.update(movieRef, {
          'vote_sum': sum,
          'vote_count': count,
          'app_rating': count > 0 ? sum / count : 0.0,
        });
      }
    });

    await createNotification(
      currentUid!,
      "${movie.title} filmine yorum yaptın.",
      movie.id,
      'comment',
    );
  }

  Future<void> deleteReview(String reviewId) async {
    final doc = await _firestore.collection('reviews').doc(reviewId).get();
    if (!doc.exists) return;
    int mid = doc.data()!['movie_id'];
    double rating = (doc.data()!['rating'] ?? 0).toDouble();

    final movieRef = _firestore.collection('app_movies').doc(mid.toString());
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(movieRef);
      if (snap.exists) {
        double sum = (snap.data()!['vote_sum'] ?? 0).toDouble() - rating;
        int count = (snap.data()!['vote_count'] ?? 0).toInt() - 1;
        if (count < 0) count = 0;
        if (sum < 0) sum = 0;
        tx.update(movieRef, {
          'vote_sum': sum,
          'vote_count': count,
          'app_rating': count > 0 ? sum / count : 0.0,
        });
      }
    });
    await _firestore.collection('reviews').doc(reviewId).delete();
  }

  Future<void> editReview(String id, String comment) async => _firestore
      .collection('reviews')
      .doc(id)
      .update({'comment': comment, 'is_edited': true});

  Future<void> toggleLikeReview(String id) async {
    if (currentUid == null) return;
    final docRef = _firestore.collection('reviews').doc(id);
    final doc = await docRef.get();
    if (doc.exists) {
      List likes = doc.data()?['likes'] ?? [];
      if (likes.contains(currentUid)) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([currentUid]),
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([currentUid]),
        });
        if (doc.data()?['user_id'] != currentUid) {
          createNotification(
            doc.data()?['user_id'],
            "Birisi yorumunu beğendi.",
            doc.data()?['movie_id'],
            'like',
          );
        }
      }
    }
  }

  Future<void> replyToReview(String id, String text) async {
    if (currentUid == null) return;
    final parent = await _firestore.collection('reviews').doc(id).get();
    final userName = currentEmail?.split('@')[0];
    await _firestore.collection('reviews').doc(id).collection('replies').add({
      'user_id': currentUid,
      'user_name': userName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (parent.exists && parent.data()?['user_id'] != currentUid) {
      createNotification(
        parent.data()?['user_id'],
        "Yorumuna cevap geldi.",
        parent.data()?['movie_id'],
        'reply',
      );
    }
  }

  Future<void> createNotification(
    String recipientId,
    String message,
    int movieId,
    String type,
  ) async {
    await _firestore.collection('notifications').add({
      'recipient_id': recipientId,
      'message': message,
      'movie_id': movieId,
      'type': type,
      'is_read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- YENİ EKLENEN: BİLDİRİMLERİ SİL ---
  Future<void> clearAllNotifications() async {
    if (currentUid == null) return;
    final batch = _firestore.batch();
    final snapshots = await _firestore
        .collection('notifications')
        .where('recipient_id', isEqualTo: currentUid)
        .get();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<List<Movie>> fetchAppTopRatedMovies() async {
    try {
      final qs = await _firestore
          .collection('app_movies')
          .where('app_rating', isGreaterThan: 6.0)
          .orderBy('app_rating', descending: true)
          .limit(20)
          .get();
      return qs.docs.map((d) => Movie.fromMap(d.data())).toList();
    } catch (e) {
      return [];
    }
  }
}
