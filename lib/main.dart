import 'package:flutter/material.dart';
import 'package:mobile_app_project/auth/auth.dart';
import 'package:mobile_app_project/auth/login_or_register.dart';
import 'package:mobile_app_project/pages/home_page.dart';
import 'package:mobile_app_project/pages/profile_page.dart';
import 'package:mobile_app_project/pages/users_page.dart';
import 'package:mobile_app_project/pages/settings_page.dart';
import 'package:mobile_app_project/themes/theme_provider.dart';
import 'package:mobile_app_project/providers/user_preferences_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  // initialize flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // setup firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserPreferencesProvider()),
      ],
      child: Consumer2<ThemeProvider, UserPreferencesProvider>(
        builder: (context, themeProvider, prefsProvider, child) {
          // load user preferences on app start
          if (!prefsProvider.isLoaded) {
            prefsProvider.loadPreferences();
          }
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Nova - Social Platform',
            theme: themeProvider.themeData,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthPage(),
              '/login_register_page': (context) => const LoginOrRegister(),
              '/home_page': (context) => HomePage(),
              '/profile_page': (context) => ProfilePage(),
              '/users_page': (context) => const UsersPage(),
              '/settings': (context) => const SettingsPage(),
            },
          );
        },
      ),
    );
  }
}
