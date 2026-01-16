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
        'role': 'user',
        'is_blocked': false,
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

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (user == null || email == null) return;

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      print("The password has been changed successfully.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'You have entered your current password incorrectly.';
      } else if (e.code == 'weak-password') {
        throw 'Your new password is too weak. It must be at least 6 characters long.';
      } else {
        throw 'Error: ${e.message}';
      }
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  Future<void> clearActivityLog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = _firestore.batch();
    final snapshots = await _firestore
        .collection('user_activities')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
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

  Future<void> updateFavoriteMovie(Movie movie, bool isAdding) async {
    if (currentUid == null) return;
    if (isAdding) {
      await _firestore.collection('users').doc(currentUid).update({
        'favorites_movies': FieldValue.arrayUnion([movie.toMap()]),
      });
      await logUserActivity(
        "${movie.title} added to favorites.",
        movie.id,
        'favorite',
      );
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
    await logUserActivity("New list created: $name", 0, 'list_create');
  }

  Future<void> addToList(String listId, Map<String, dynamic> itemData) async {
    if (currentUid == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('lists')
        .doc(listId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      List currentItems = docSnapshot.data()?['items'] ?? [];
      bool alreadyExists = currentItems.any(
        (item) => item['id'] == itemData['id'],
      );
      if (alreadyExists) return;
    }

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
          'movies': FieldValue.arrayRemove([itemData]),
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

    await createNotification(
      targetUid,
      "Sent you a friend request.",
      0,
      'friend_request',
    );
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

    await createNotification(
      requesterUid,
      "Arkadaşlık isteğini kabul etti.",
      0,
      'friend_request',
    );
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
    for (var m in msgs.docs) {
      await m.reference.delete();
    }
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

    try {
      final chatId = _getChatId(currentUid!, receiverUid);

      Map<String, dynamic> msgData = {
        'sender_id': currentUid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      };

      if (sharedMovie != null) {
        msgData['movie_id'] = sharedMovie.id;
        msgData['movie_title'] = sharedMovie.title;
        msgData['poster_path'] = sharedMovie.poster;
      }
      if (sharedList != null) {
        msgData['list_id'] = sharedList['id'];
        msgData['list_name'] = sharedList['name'];
        msgData['list_count'] = sharedList['count'];
      }

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(msgData);
    } catch (e) {
      print("Chat Send Error: $e");
    }

    try {
      await _firestore.collection('notifications').add({
        'recipient_id': receiverUid,
        'sender_id': currentUid,
        'message':
            "Sent you a message: ${text.length > 20 ? '${text.substring(0, 20)}...' : text}",
        'type': 'message',
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'movie_id': sharedMovie?.id ?? 0,
      });
    } catch (e) {
      print("Notif Send Error: $e");
    }
  }

  Future<void> renameList(String listId, String newName) async {
    if (currentUid == null) return;
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('lists')
        .doc(listId)
        .update({'name': newName});
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
          'name': "$listName (Copy)",
          'type': type,
          'created_at': FieldValue.serverTimestamp(),
          'items': items,
        });

    await logUserActivity("$listName You copied the list.", 0, 'list_import');
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

    final userDoc = await _firestore.collection('users').doc(currentUid).get();
    final userData = userDoc.data();

    final String userRole = userData?['role'] ?? 'user';

    int iconId = (userDoc.exists && userData!.containsKey('profile_icon_id'))
        ? userData['profile_icon_id']
        : 0;

    final userName = currentEmail?.split('@')[0] ?? 'User';

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
      for (var d in prev.docs) {
        batch.update(d.reference, {
          'rating': rating,
          'profile_icon_id': iconId,
          'user_role': userRole,
        });
      }
      await batch.commit();
    }

    await _firestore.collection('reviews').add({
      'movie_id': movie.id,
      'movie_title': movie.title,
      'poster_path': movie.poster,
      'user_id': currentUid,
      'user_name': userName,
      'user_role': userRole,
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

    await logUserActivity(
      "${movie.title} You commented on the movie.",
      movie.id,
      'review',
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
            "Someone liked your comment.",
            doc.data()?['movie_id'],
            'like',
          );
        }

        await logUserActivity(
          "You liked a comment.",
          doc.data()?['movie_id'],
          'like',
        );
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
        "You received a reply to your comment.",
        parent.data()?['movie_id'],
        'reply',
      );
    }

    await logUserActivity(
      "You replied to a comment.",
      parent.data()?['movie_id'],
      'reply',
    );
  }

  Future<void> createNotification(
    String recipientId,
    String message,
    int movieId,
    String type,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_id': recipientId,
        'message': message,
        'movie_id': movieId,
        'type': type,
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Notification Error: $e");
    }
  }

  Future<void> logUserActivity(String text, int? movieId, String type) async {
    if (currentUid == null) return;
    await _firestore.collection('user_activities').add({
      'user_id': currentUid,
      'text': text,
      'movie_id': movieId ?? 0,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

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

  Future<void> clearAllActivities() async {
    if (currentUid == null) return;
    final batch = _firestore.batch();
    final snapshots = await _firestore
        .collection('user_activities')
        .where('user_id', isEqualTo: currentUid)
        .get();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<QuerySnapshot> getUnreadNotificationsStream() {
    if (currentUid == null) return const Stream.empty();
    return _firestore
        .collection('notifications')
        .where('recipient_id', isEqualTo: currentUid)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String docId) async {
    await _firestore.collection('notifications').doc(docId).update({
      'is_read': true,
    });
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

  Future<bool> isAdmin() async {
    if (currentUid == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(currentUid).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  Stream<QuerySnapshot> getAllReviewsStream() {
    return _firestore
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  Stream<QuerySnapshot> getAllGroupsStream() {
    return _firestore.collection('groups').snapshots();
  }

  Future<void> adminDeleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
  }

  Future<void> adminToggleBlock(String userId, bool blockStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'is_blocked': blockStatus,
      });
    } catch (e) {
      print("Block Error: $e");
      rethrow;
    }
  }

  Future<void> adminJoinGroupDirectly(String groupId) async {
    if (currentUid == null) return;
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([currentUid]),
    });
  }
}
