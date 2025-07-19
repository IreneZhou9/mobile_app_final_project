import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../helper/helper_function.dart';
import '../providers/user_preferences_provider.dart';
import '../database/firestore.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // handle user login
  void login() async {
    // show loading indicator
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // validate input
    if (emailController.text.trim().isEmpty) {
      Navigator.pop(context);
      displayMessageToUser("Please enter your email address", context);
      return;
    }

    if (passwordController.text.isEmpty) {
      Navigator.pop(context);
      displayMessageToUser("Please enter your password", context);
      return;
    }

    try {
      // attempt login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // dismiss loading
      if (context.mounted) Navigator.pop(context);

      // load user preferences after successful login
      if (context.mounted) {
        final prefsProvider = Provider.of<UserPreferencesProvider>(context, listen: false);
        await prefsProvider.loadPreferences();
        
        // Create welcome post if user doesn't have any posts
        final database = FireStoreDatabase();
        await database.createWelcomePost();
      }

      // show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back to Nova!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String errorMessage = _getErrorMessage(e.code);
      displayMessageToUser(errorMessage, context);
    } catch (e) {
      Navigator.pop(context);
      displayMessageToUser("Login failed: ${e.toString()}", context);
    }
  }

  // get user-friendly error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      default:
        return 'Login failed. Please check your credentials and try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, prefs, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          resizeToAvoidBottomInset: true, // 防止键盘溢出
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // app logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: prefs.currentAccentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_album,
                        size: 60,
                        color: prefs.currentAccentColor,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // welcome message
                    Text(
                      "Welcome to N O V A",
                      style: prefs.getTextStyle(
                        multiplier: 1.75, // 28/16
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to your account to continue",
                      style: prefs.getTextStyle(
                        multiplier: 1.0, // 16/16
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // email field
                    MyTextfield(
                      hintText: "Email address",
                      obscureText: false,
                      controller: emailController,
                    ),
                    const SizedBox(height: 15),

                    // password field
                    MyTextfield(
                      hintText: "Password",
                      obscureText: true,
                      controller: passwordController,
                    ),
                    const SizedBox(height: 10),

                    // forgot password (optional future feature)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Forgot password feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Text(
                          "Forgot password?",
                          style: prefs.getTextStyle(
                            color: prefs.currentAccentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // login button
                    SizedBox(
                      width: double.infinity,
                      child: MyButton(
                        text: "Sign In",
                        onTap: login,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // register redirect
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: prefs.getTextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            "Create one here",
                            style: prefs.getTextStyle(
                              fontWeight: FontWeight.bold,
                              color: prefs.currentAccentColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // app version info
                    Text(
                      "Nova Social Platform v1.0.0",
                      style: prefs.getTextStyle(
                        multiplier: 0.75, // 12/16
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
