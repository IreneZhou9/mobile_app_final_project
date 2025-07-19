// firestore database for managing posts and user data
// collections: Posts, Users, UserPreferences

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDatabase {
  // current logged in user
  User? user = FirebaseAuth.instance.currentUser;
  
  // collection references
  final CollectionReference posts = FirebaseFirestore.instance.collection('Posts');
  final CollectionReference users = FirebaseFirestore.instance.collection('Users');
  final CollectionReference userPreferences = FirebaseFirestore.instance.collection('UserPreferences');

  // add new post with privacy setting
  Future<void> addPost(String message, {bool isPrivate = false, String? imageUrl}) async {
    await posts.add({
      'UserEmail': user!.email,
      'PostMessage': message,
      'TimeStamp': Timestamp.now(),
      'IsPrivate': isPrivate,
      'ImageUrl': imageUrl ?? '',
      'LikeCount': 0,
      'LikedBy': [],
    });
  }

  // get public posts stream (for all users)
  Stream<QuerySnapshot> getPublicPostsStream() {
    try {
      return posts
          .orderBy('TimeStamp', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting public posts: $e');
      return Stream.empty();
    }
  }

  // get user's own posts stream (both public and private)
  Stream<QuerySnapshot> getUserPostsStream({String? userEmail}) {
    try {
      String targetEmail = userEmail ?? user!.email!;
      // Use simpler query to avoid index issues
      return posts
          .where('UserEmail', isEqualTo: targetEmail)
          .snapshots();
    } catch (e) {
      print('Error getting user posts: $e');
      return Stream.empty();
    }
  }

  // get all posts for home feed (simple version)
  Stream<QuerySnapshot> getHomeFeedStream() {
    try {
      return posts
          .orderBy('TimeStamp', descending: true)
          .limit(50) // limit to improve performance
          .snapshots();
    } catch (e) {
      print('Error getting home feed: $e');
      return Stream.empty();
    }
  }

  // toggle like on post
  Future<void> toggleLike(String postId, bool isLiked) async {
    DocumentReference postRef = posts.doc(postId);
    
    if (isLiked) {
      // unlike
      await postRef.update({
        'LikeCount': FieldValue.increment(-1),
        'LikedBy': FieldValue.arrayRemove([user!.email]),
      });
    } else {
      // like
      await postRef.update({
        'LikeCount': FieldValue.increment(1),
        'LikedBy': FieldValue.arrayUnion([user!.email]),
      });
    }
  }

  // delete post (only if user owns it)
  Future<void> deletePost(String postId, String postOwnerEmail) async {
    if (user!.email == postOwnerEmail) {
      await posts.doc(postId).delete();
    }
  }

  // create user profile
  Future<void> createUserProfile({
    required String email,
    required String username,
    String? profileImageUrl,
    String? bio,
  }) async {
    await users.doc(email).set({
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl ?? '',
      'bio': bio ?? '',
      'joinedDate': Timestamp.now(),
      'isOnboardingComplete': false,
    });
  }

  // update user profile
  Future<void> updateUserProfile({
    String? username,
    String? profileImageUrl,
    String? bio,
  }) async {
    Map<String, dynamic> updates = {};
    if (username != null) updates['username'] = username;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    if (bio != null) updates['bio'] = bio;

    if (updates.isNotEmpty) {
      await users.doc(user!.email).update(updates);
    }
  }

  // get user profile
  Future<DocumentSnapshot> getUserProfile([String? email]) async {
    final userEmail = email ?? user?.email;
    if (userEmail == null) {
      throw Exception('No user email provided');
    }
    return await users.doc(userEmail).get();
  }

  // save user preferences
  Future<void> saveUserPreferences({
    required double fontSize,
    required String themeMode, // 'light', 'dark', 'system'
    required String accentColor,
    required bool notificationsEnabled,
  }) async {
    await userPreferences.doc(user!.email).set({
      'fontSize': fontSize,
      'themeMode': themeMode,
      'accentColor': accentColor,
      'notificationsEnabled': notificationsEnabled,
      'lastUpdated': Timestamp.now(),
    });
  }

  // get user preferences
  Future<DocumentSnapshot> getUserPreferences() async {
    return await userPreferences.doc(user!.email).get();
  }

  // mark onboarding as complete
  Future<void> completeOnboarding() async {
    await users.doc(user!.email).update({
      'isOnboardingComplete': true,
    });
  }

  // check if user has completed onboarding
  Future<bool> isOnboardingComplete() async {
    DocumentSnapshot doc = await users.doc(user!.email).get();
    if (doc.exists) {
      return doc.get('isOnboardingComplete') ?? false;
    }
    return false;
  }

  // get all users for discovery
  Stream<QuerySnapshot> getAllUsersStream() {
    return users.orderBy('joinedDate', descending: true).snapshots();
  }

  // create initial welcome post for new users
  Future<void> createWelcomePost() async {
    try {
      // Check if user already has posts
      QuerySnapshot existingPosts = await posts
          .where('UserEmail', isEqualTo: user!.email)
          .limit(1)
          .get();
      
      // Only create welcome post if user has no posts
      if (existingPosts.docs.isEmpty) {
        await posts.add({
          'UserEmail': user!.email,
          'PostMessage': '🎉 Welcome to Nova! This is your first post. Start sharing your thoughts with the community!',
          'TimeStamp': Timestamp.now(),
          'IsPrivate': false,
          'ImageUrl': '',
          'LikeCount': 0,
          'LikedBy': [],
        });
      }
    } catch (e) {
      print('Error creating welcome post: $e');
    }
  }

  // clear user state
  void clearState() {
    // _userPreferences = null; // This line was not in the new_code, so it's removed.
    user = null;
  }
}
