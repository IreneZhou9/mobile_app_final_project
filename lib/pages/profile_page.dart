import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/firestore.dart';
import '../providers/user_preferences_provider.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  // database access
  final FireStoreDatabase database = FireStoreDatabase();

  // current logged in user
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // tab controller for posts filter
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // fetch user profile
  Future<DocumentSnapshot> getUserProfile() async {
    return await database.getUserProfile(currentUser!.email!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, prefs, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          resizeToAvoidBottomInset: false, // 防止键盘弹出时的布局问题
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // app bar with profile info
                SliverAppBar(
                  expandedHeight: 300,
                  floating: false,
                  pinned: true,
                  backgroundColor: prefs.currentAccentColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            prefs.currentAccentColor,
                            prefs.currentAccentColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: getUserProfile(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            );
                          }

                          if (snapshot.hasError || !snapshot.hasData) {
                            return _buildDefaultProfileHeader(context, prefs);
                          }

                          Map<String, dynamic>? userData = 
                              snapshot.data!.data() as Map<String, dynamic>?;

                          return _buildProfileHeader(context, prefs, userData);
                        },
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _showEditProfileDialog(context, prefs),
                    ),
                  ],
                ),

                // posts section header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PostsHeaderDelegate(
                    child: Material(
                      color: Theme.of(context).colorScheme.background,
                      child: Container(
                        height: 70, // 固定高度防止溢出
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.background,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: TabBar(
                                controller: _tabController,
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
                                  Tab(text: "Public Only"),
                                ],
                              ),
                            ),
                            Container(
                              height: 1,
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // posts content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsList(context, prefs, showAll: true),
                      _buildPostsList(context, prefs, showAll: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultProfileHeader(BuildContext context, UserPreferencesProvider prefs) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 60,
                color: prefs.currentAccentColor,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<DocumentSnapshot>(
              future: getUserProfile(),
              builder: (context, snapshot) {
                String displayName = 'Unknown User';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  displayName = data?['username'] ?? currentUser?.email?.split('@')[0] ?? 'Unknown User';
                } else {
                  displayName = currentUser?.email?.split('@')[0] ?? 'Unknown User';
                }
                
                return Text(
                  displayName,
                  style: prefs.getTextStyle(
                    multiplier: 1.5, // 24/16
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              currentUser?.email ?? '',
              style: prefs.getTextStyle(
                multiplier: 1.0, // 16/16
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Welcome to Nova! Update your profile to get started.",
              style: prefs.getTextStyle(
                multiplier: 0.875, // 14/16
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserPreferencesProvider prefs, Map<String, dynamic>? userData) {
    String username = userData?['username'] ?? currentUser?.email?.split('@')[0] ?? 'Unknown User';
    String bio = userData?['bio'] ?? '';
    String profileImageUrl = userData?['profileImageUrl'] ?? '';
    Timestamp? joinedDate = userData?['joinedDate'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // profile image
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
              child: profileImageUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: prefs.currentAccentColor,
                    )
                  : null,
            ),
            const SizedBox(height: 20),

            // username
            Text(
              username,
              style: prefs.getTextStyle(
                multiplier: 1.5, // 24/16
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // email
            Text(
              currentUser?.email ?? '',
              style: prefs.getTextStyle(
                multiplier: 1.0, // 16/16
                color: Colors.white.withOpacity(0.9),
              ),
            ),

            // bio
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                bio,
                style: prefs.getTextStyle(
                  multiplier: 0.875, // 14/16
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // joined date
            if (joinedDate != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Joined ${_formatDate(joinedDate.toDate())}',
                    style: prefs.getTextStyle(
                      multiplier: 0.75, // 12/16
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, UserPreferencesProvider prefs, {required bool showAll}) {
    return StreamBuilder<QuerySnapshot>(
      stream: database.getUserPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('ProfilePageError: ${snapshot.error}');
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
                  'Please try again',
                  style: prefs.getTextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {}); // trigger rebuild
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

        final allPosts = snapshot.data?.docs ?? [];
        
        // Sort posts by timestamp (newest first) - do this in UI to avoid index issues
        allPosts.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['TimeStamp'] as Timestamp?;
          final bTime = bData['TimeStamp'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        
        // filter posts based on tab
        final posts = showAll 
            ? allPosts 
            : allPosts.where((post) {
                final data = post.data() as Map<String, dynamic>;
                return data['IsPrivate'] != true;
              }).toList();

        if (posts.isEmpty) {
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
                  showAll ? "No posts yet" : "No public posts yet",
                  style: prefs.getTextStyle(
                    multiplier: 1.125, // 18/16
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start sharing your thoughts with the community!",
                  style: prefs.getTextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/home_page');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: prefs.currentAccentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Create a test post for debugging
                        try {
                          await database.addPost(
                            "📱 This is a test post from my profile page! Everything seems to be working correctly now. 🎉",
                            isPrivate: false,
                          );
                          setState(() {}); // refresh the page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test post created!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Test Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;
            return _buildPostCard(context, prefs, post.id, data);
          },
        );
      },
    );
  }

  Widget _buildPostCard(BuildContext context, UserPreferencesProvider prefs, String postId, Map<String, dynamic> data) {
    String message = data['PostMessage'] ?? '';
    String userEmail = data['UserEmail'] ?? '';
    bool isPrivate = data['IsPrivate'] ?? false;
    String imageUrl = data['ImageUrl'] ?? '';
    int likeCount = data['LikeCount'] ?? 0;
    Timestamp timestamp = data['TimeStamp'];
    String timeAgo = _getTimeAgo(timestamp.toDate());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // post header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPrivate ? Icons.lock : Icons.public,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPrivate ? "Private" : "Public",
                      style: prefs.getTextStyle(
                        multiplier: 0.75, // 12/16
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timeAgo,
                      style: prefs.getTextStyle(
                        multiplier: 0.75, // 12/16
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                if (userEmail == currentUser?.email) // only show for own posts
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(postId);
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

            // post stats
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 16,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '$likeCount likes',
                  style: prefs.getTextStyle(
                    multiplier: 0.75, // 12/16
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deletePost(String postId) {
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
                await database.deletePost(postId, currentUser!.email!);
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

  void _showEditProfileDialog(BuildContext context, UserPreferencesProvider prefs) {
    final bioController = TextEditingController();
    final usernameController = TextEditingController();

    // load current data
    getUserProfile().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        bioController.text = data?['bio'] ?? '';
        usernameController.text = data?['username'] ?? '';
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Edit Profile',
          style: prefs.getTextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await database.updateUserProfile(
                  username: usernameController.text.trim(),
                  bio: bioController.text.trim(),
                );
                setState(() {}); // refresh the profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating profile: $e')),
                );
              }
            },
            child: const Text('Save'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PostsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PostsHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 70.0; // 与容器高度匹配

  @override
  double get minExtent => 70.0; // 与容器高度匹配

  @override
  bool shouldRebuild(_PostsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
