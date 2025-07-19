import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app_project/auth/login_or_register.dart';
import '../pages/home_page.dart';

// handles authentication state
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Debug: print authentication state
          print('Auth state changed: ${snapshot.hasData ? 'User logged in' : 'User logged out'}');
          
          // Handle connection state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // Handle errors
          if (snapshot.hasError) {
            print('Auth error: ${snapshot.error}');
            return const Center(
              child: Text('Authentication error. Please restart the app.'),
            );
          }
          
          // user is logged in
          if (snapshot.hasData && snapshot.data != null) {
            print('User authenticated: ${snapshot.data!.email}');
            return HomePage();
          } else {  
            print('No user authenticated, showing login page');
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
