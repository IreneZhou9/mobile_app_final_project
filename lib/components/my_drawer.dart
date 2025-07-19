import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app_project/themes/theme_provider.dart';
import 'package:mobile_app_project/providers/user_preferences_provider.dart';
import 'package:mobile_app_project/database/firestore.dart';

class MyDrawer extends StatelessWidget {
  final FirestoreDatabase database = FirestoreDatabase();
  
  MyDrawer({super.key});

  // sign out user
  Future<void> logout() async {
    try {
      // clear firestore state
      database.clearState();
      
      // sign out from firebase
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, prefs, child) {
        return Drawer(
          backgroundColor: Theme.of(context).colorScheme.background,
          child: Column(
            children: [
              // custom drawer header
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      prefs.currentAccentColor,
                      prefs.currentAccentColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: prefs.currentAccentColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "N O V A",
                          style: prefs.getTextStyle(
                            multiplier: 1.5, // 24/16
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Social Platform",
                          style: prefs.getTextStyle(
                            multiplier: 0.875, // 14/16
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // navigation items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildNavItem(
                      context,
                      prefs,
                      icon: Icons.home_rounded,
                      title: "Home",
                      subtitle: "Your social feed",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home_page',
                          (route) => false,
                        );
                      },
                    ),

                    _buildNavItem(
                      context,
                      prefs,
                      icon: Icons.person_rounded,
                      title: "My Profile",
                      subtitle: "View and edit profile",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile_page');
                      },
                    ),

                    _buildNavItem(
                      context,
                      prefs,
                      icon: Icons.group_rounded,
                      title: "All Users",
                      subtitle: "Browse user directory",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/users_page');
                      },
                    ),

                    const SizedBox(height: 20),

                    // divider
                    Divider(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      indent: 20,
                      endIndent: 20,
                    ),

                    const SizedBox(height: 10),

                    _buildNavItem(
                      context,
                      prefs,
                      icon: Icons.settings_rounded,
                      title: "Settings",
                      subtitle: "Customize your experience",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),

                    _buildNavItem(
                      context,
                      prefs,
                      icon: Provider.of<ThemeProvider>(context).themeModeIcon,
                      title: Provider.of<ThemeProvider>(context).themeModeDisplayText,
                      subtitle: "Tap to toggle theme",
                      onTap: () {
                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                      },
                    ),

                    const SizedBox(height: 20),

                    // logout section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                        ),
                        title: Text(
                          "Sign Out",
                          style: prefs.getTextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: Text(
                          "Log out of your account",
                          style: prefs.getTextStyle(
                            multiplier: 0.75, // 12/16
                            color: Colors.red.withOpacity(0.8),
                          ),
                        ),
                        onTap: () {
                          _showLogoutDialog(context, prefs);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // app info
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Nova v1.0.0",
                  style: prefs.getTextStyle(
                    multiplier: 0.75, // 12/16
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    UserPreferencesProvider prefs, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          color: prefs.currentAccentColor,
          size: 24,
        ),
        title: Text(
          title,
          style: prefs.getTextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: prefs.getTextStyle(
            multiplier: 0.75, // 12/16
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, UserPreferencesProvider prefs) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: prefs.currentAccentColor),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: prefs.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to sign out of your account?',
            style: prefs.getTextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: prefs.getTextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close dialog and drawer
                Navigator.pop(context);
                Navigator.pop(context);
                
                // Perform logout
                await logout();
                
                // Navigate to auth page and clear stack
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sign Out',
                style: prefs.getTextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
