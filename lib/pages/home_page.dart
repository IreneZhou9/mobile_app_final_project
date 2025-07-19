import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app_project/components/my_drawer.dart';
import 'package:mobile_app_project/database/firestore.dart';
import 'package:mobile_app_project/providers/user_preferences_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // database access
  final FireStoreDatabase database = FireStoreDatabase();

  // input controller
  final TextEditingController newPostController = TextEditingController();

  // post privacy setting
  bool isPrivatePost = false;

  // image upload
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;

  // tab controller for feed filtering
  late TabController _tabController;

  // feed type
  String currentFeedType = 'all'; // 'all', 'public', 'private'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    newPostController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // pick image for post
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
          });
        } else {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // remove selected image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  // upload image to firebase storage
  Future<String?> _uploadImage() async {
    if (_selectedImage == null && _selectedImageBytes == null) return null;

    try {
      String fileName = 'post_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = FirebaseStorage.instance.ref().child("post_images/$fileName");

      TaskSnapshot uploadTask;
      if (kIsWeb && _selectedImageBytes != null) {
        uploadTask = await ref.putData(
          _selectedImageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (!kIsWeb && _selectedImage != null) {
        uploadTask = await ref.putFile(_selectedImage!);
      } else {
        return null;
      }

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // handle post submission
  Future<void> postMessage() async {
    if (newPostController.text.trim().isEmpty && _selectedImage == null && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something or add an image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null || _selectedImageBytes != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      await database.addPost(
        newPostController.text.trim(),
        isPrivate: isPrivatePost,
        imageUrl: imageUrl,
      );

      // clear form
      newPostController.clear();
      setState(() {
        isPrivatePost = false;
        _selectedImage = null;
        _selectedImageBytes = null;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPrivatePost ? 'Private post shared!' : 'Public post shared!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print('Post creation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // get posts stream based on current feed type
  Stream<QuerySnapshot> _getPostsStream() {
    // Always use home feed stream and filter in UI
    return database.getHomeFeedStream();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, prefs, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          resizeToAvoidBottomInset: true, // 确保键盘弹出时调整布局
          appBar: AppBar(
            title: Text(
              "N O V A",
              style: prefs.getTextStyle(
                fontWeight: FontWeight.bold,
                multiplier: 1.2,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.background,
            foregroundColor: Theme.of(context).colorScheme.inversePrimary,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Material(
                color: Theme.of(context).colorScheme.background,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (index) {
                      setState(() {
                        currentFeedType = ['all', 'public', 'private'][index];
                      });
                    },
                    labelColor: prefs.currentAccentColor,
                    unselectedLabelColor: Theme.of(context).colorScheme.secondary,
                    indicatorColor: prefs.currentAccentColor,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: prefs.getTextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: prefs.getTextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: "All Posts"),
                      Tab(text: "Public"),
                      Tab(text: "My Private"),
                    ],
                  ),
                ),
              ),
            ),
          ),
          drawer: const MyDrawer(),
          body: Column(
            children: [
              // post creation section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // text input
                    TextField(
                      controller: newPostController,
                      style: prefs.getTextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: prefs.getTextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.background,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    // selected image preview
                    if (_selectedImage != null || _selectedImageBytes != null) ...[
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb && _selectedImageBytes != null
                                ? Image.memory(
                                    _selectedImageBytes!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : !kIsWeb && _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : const SizedBox(),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                padding: EdgeInsets.zero,
                                onPressed: _removeImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // post options
                    Row(
                      children: [
                        // image picker button
                        IconButton(
                          onPressed: _isUploading ? null : _pickImage,
                          icon: Icon(
                            Icons.image,
                            color: prefs.currentAccentColor,
                          ),
                        ),

                        // privacy toggle
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                isPrivatePost ? Icons.lock : Icons.public,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isPrivatePost = !isPrivatePost;
                                  });
                                },
                                child: Text(
                                  isPrivatePost ? "Private Post" : "Public Post",
                                  style: prefs.getTextStyle(
                                    multiplier: 0.9,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                              Switch(
                                value: isPrivatePost,
                                onChanged: (value) {
                                  setState(() {
                                    isPrivatePost = value;
                                  });
                                },
                                activeColor: prefs.currentAccentColor,
                              ),
                            ],
                          ),
                        ),

                        // post button
                        ElevatedButton(
                          onPressed: _isUploading ? null : postMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: prefs.currentAccentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Post",
                                  style: prefs.getTextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // posts feed
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getPostsStream(),
                  builder: (context, snapshot) {
                    // loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // error state
                    if (snapshot.hasError) {
                      print('HomePageError: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.withOpacity(0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading posts',
                              style: prefs.getTextStyle(
                                multiplier: 1.2,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your internet connection\nand try again',
                              style: prefs.getTextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {}); // 触发重新加载
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: prefs.currentAccentColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // get posts data
                    final posts = snapshot.data?.docs ?? [];
                    
                    // filter posts based on current feed type
                    final filteredPosts = posts.where((post) {
                      final data = post.data() as Map<String, dynamic>;
                      String postUserEmail = data['UserEmail'] ?? '';
                      bool isPrivate = data['IsPrivate'] ?? false;
                      String? currentUserEmail = database.user?.email;
                      
                      switch (currentFeedType) {
                        case 'public':
                          // Show only public posts
                          return !isPrivate;
                        case 'private':
                          // Show only current user's private posts
                          return isPrivate && postUserEmail == currentUserEmail;
                        default:
                          // Show public posts + current user's private posts
                          if (!isPrivate) return true; // all public posts
                          return postUserEmail == currentUserEmail; // only user's private posts
                      }
                    }).toList();

                    // empty state
                    if (filteredPosts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.post_add,
                              size: 64,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentFeedType == 'public' 
                                  ? "No public posts yet"
                                  : currentFeedType == 'private'
                                      ? "No private posts yet"
                                      : "No posts yet",
                              style: prefs.getTextStyle(
                                multiplier: 1.1,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Be the first to share something!",
                              style: prefs.getTextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // render posts list
                    return ListView.builder(
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        final data = post.data() as Map<String, dynamic>;
                        
                        return _buildPostCard(context, post.id, data, prefs);
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

  Widget _buildPostCard(BuildContext context, String postId, Map<String, dynamic> data, UserPreferencesProvider prefs) {
    String message = data['PostMessage'] ?? '';
    String userEmail = data['UserEmail'] ?? '';
    bool isPrivate = data['IsPrivate'] ?? false;
    String imageUrl = data['ImageUrl'] ?? '';
    int likeCount = data['LikeCount'] ?? 0;
    List<dynamic> likedBy = data['LikedBy'] ?? [];
    bool isLikedByUser = likedBy.contains(database.user?.email);
    Timestamp timestamp = data['TimeStamp'];

    // calculate time ago
    String timeAgo = _getTimeAgo(timestamp.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // post header with user info
            FutureBuilder<DocumentSnapshot>(
              future: database.getUserProfile(userEmail),
              builder: (context, userSnapshot) {
                String displayName = userEmail.split('@')[0]; // fallback
                
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  displayName = userData?['username'] ?? userEmail.split('@')[0];
                }

                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: prefs.currentAccentColor,
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: prefs.getTextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                timeAgo,
                                style: prefs.getTextStyle(
                                  multiplier: 0.8,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isPrivate ? Icons.lock : Icons.public,
                                size: 14,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // delete button (only for own posts)
                    if (userEmail == database.user?.email)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deletePost(postId, userEmail);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // post content
            if (message.isNotEmpty) ...[
              Text(
                message,
                style: prefs.getTextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // post image
            if (imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      child: const Center(child: Icon(Icons.error)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // post actions
            Row(
              children: [
                // like button
                GestureDetector(
                  onTap: () => database.toggleLike(postId, isLikedByUser),
                  child: Row(
                    children: [
                      Icon(
                        isLikedByUser ? Icons.favorite : Icons.favorite_border,
                        color: isLikedByUser ? Colors.red : Theme.of(context).colorScheme.secondary,
                      ),
                      if (likeCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          likeCount.toString(),
                          style: prefs.getTextStyle(
                            multiplier: 0.9,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deletePost(String postId, String userEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await database.deletePost(postId, userEmail);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting post: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
