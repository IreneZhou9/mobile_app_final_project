import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_preferences_provider.dart';
import '../themes/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<UserPreferencesProvider>(
        builder: (context, prefs, child) {
          if (!prefs.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // appearance section
                  _buildSectionHeader(context, "Appearance", Icons.palette),
                  const SizedBox(height: 16),

                  // theme mode
                  _buildCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Theme Mode",
                          style: prefs.getTextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: UserPreferencesProvider.themeModeOptions.map((mode) {
                            return ChoiceChip(
                              label: Text(_capitalizeFirst(mode)),
                              selected: prefs.themeMode == mode,
                              onSelected: (selected) {
                                if (selected) {
                                  prefs.setThemeMode(mode);
                                  // update theme provider accordingly
                                  if (mode == 'light') {
                                    Provider.of<ThemeProvider>(context, listen: false).setLightMode();
                                  } else if (mode == 'dark') {
                                    Provider.of<ThemeProvider>(context, listen: false).setDarkMode();
                                  }
                                }
                              },
                              selectedColor: prefs.currentAccentColor.withOpacity(0.3),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // accent color
                  _buildCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Accent Color",
                          style: prefs.getTextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: UserPreferencesProvider.accentColorOptions.entries.map((entry) {
                            return GestureDetector(
                              onTap: () => prefs.setAccentColor(entry.key),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: entry.value,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: prefs.accentColor == entry.key 
                                        ? Theme.of(context).colorScheme.inversePrimary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: prefs.accentColor == entry.key
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // text settings section
                  _buildSectionHeader(context, "Text Settings", Icons.text_fields),
                  const SizedBox(height: 16),

                  // font size
                  _buildCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Font Size",
                          style: prefs.getTextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "This is how your text will look",
                          style: prefs.getTextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: prefs.fontSize,
                          min: UserPreferencesProvider.fontSizeOptions.first,
                          max: UserPreferencesProvider.fontSizeOptions.last,
                          divisions: UserPreferencesProvider.fontSizeOptions.length - 1,
                          label: '${prefs.fontSize.toInt()}px',
                          activeColor: prefs.currentAccentColor,
                          onChanged: (value) {
                            // find closest font size option
                            double closestSize = UserPreferencesProvider.fontSizeOptions
                                .reduce((a, b) => (a - value).abs() < (b - value).abs() ? a : b);
                            prefs.setFontSize(closestSize);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // privacy & notifications section
                  _buildSectionHeader(context, "Privacy & Notifications", Icons.security),
                  const SizedBox(height: 16),

                  _buildCard(
                    context,
                    child: SwitchListTile(
                      title: Text(
                        "Push Notifications",
                        style: prefs.getTextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      subtitle: Text(
                        "Receive notifications for new posts and interactions",
                        style: prefs.getTextStyle(
                          multiplier: 0.9,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      value: prefs.notificationsEnabled,
                      activeColor: prefs.currentAccentColor,
                      onChanged: prefs.setNotificationsEnabled,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // actions section
                  _buildSectionHeader(context, "Actions", Icons.build),
                  const SizedBox(height: 16),

                  _buildCard(
                    context,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.refresh,
                            color: prefs.currentAccentColor,
                          ),
                          title: Text(
                            "Reset to Defaults",
                            style: prefs.getTextStyle(
                              color: Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          subtitle: Text(
                            "Reset all settings to default values",
                            style: prefs.getTextStyle(
                              multiplier: 0.9,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          onTap: () => _showResetDialog(context, prefs),
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        const Divider(),
                        
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: Colors.red,
                          ),
                          title: Text(
                            "Sign Out (Alternative)",
                            style: prefs.getTextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "Alternative logout method if drawer doesn't work",
                            style: prefs.getTextStyle(
                              multiplier: 0.9,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          onTap: () => _showAlternativeLogoutDialog(context, prefs),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  // 添加底部边距防止内容被遮挡
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, prefs, child) {
        return Row(
          children: [
            Icon(
              icon,
              color: prefs.currentAccentColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: prefs.getTextStyle(
                fontWeight: FontWeight.bold,
                multiplier: 1.2,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  String _capitalizeFirst(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showResetDialog(BuildContext context, UserPreferencesProvider prefs) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text('Are you sure you want to reset all settings to default values?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                prefs.resetToDefaults();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _showAlternativeLogoutDialog(BuildContext context, UserPreferencesProvider prefs) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Row(
            children: [
              Icon(Icons.logout, color: prefs.currentAccentColor),
              const SizedBox(width: 12),
              const Text('Alternative Sign Out'),
            ],
          ),
          content: const Text('This is an alternative logout method. Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: prefs.currentAccentColor),
                        const SizedBox(height: 16),
                        const Text('Signing out...'),
                      ],
                    ),
                  ),
                );
                
                try {
                  // Direct Firebase logout
                  await FirebaseAuth.instance.signOut();
                  
                  // Clear preferences
                  prefs.clearPreferences();
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully signed out via alternative method'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Alternative logout failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
} 