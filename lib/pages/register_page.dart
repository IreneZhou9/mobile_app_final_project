import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../helper/helper_function.dart';
import '../database/firestore.dart';
import '../providers/user_preferences_provider.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text controllers
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPwController = TextEditingController();

  // database instance
  final FirestoreDatabase database = FirestoreDatabase();

  // handle user registration
  void registerUser() async {
    // show loading indicator
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // check if passwords match
    if (passwordController.text != confirmPwController.text) {
      Navigator.pop(context);
      displayMessageToUser("Passwords don't match", context);
      return;
    }

    // validate input
    if (usernameController.text.trim().isEmpty) {
      Navigator.pop(context);
      displayMessageToUser("Please enter a username", context);
      return;
    }

    try {
      // create new user account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // create user profile in database
      await database.createUserProfile(
        email: userCredential.user!.email!,
        username: usernameController.text.trim(),
        bio: 'New Nova user 👋',
      );

      // initialize user preferences with defaults
      await database.saveUserPreferences(
        fontSize: 16.0,
        themeMode: 'system',
        accentColor: 'blue',
        notificationsEnabled: true,
      );

      // create welcome post for new user
      await database.createWelcomePost();

      // dismiss loading
      if (context.mounted) Navigator.pop(context);

      // show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome to Nova!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String errorMessage = _getErrorMessage(e.code);
      displayMessageToUser(errorMessage, context);
    } catch (e) {
      Navigator.pop(context);
      displayMessageToUser("Registration failed: ${e.toString()}", context);
    }
  }

  // get user-friendly error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Account creation is currently disabled.';
      default:
        return 'Registration failed. Please try again.';
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
                        Icons.person_add,
                        size: 60,
                        color: prefs.currentAccentColor,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // app name
                    Text(
                      "Join N O V A",
                      style: prefs.getTextStyle(
                        multiplier: 1.75, // 28/16
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create your account to start sharing",
                      style: prefs.getTextStyle(
                        multiplier: 1.0, // 16/16
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // username field
                    MyTextfield(
                      hintText: "Username",
                      obscureText: false,
                      controller: usernameController,
                    ),
                    const SizedBox(height: 15),

                    // email field
                    MyTextfield(
                      hintText: "Email address",
                      obscureText: false,
                      controller: emailController,
                    ),
                    const SizedBox(height: 15),

                    // password field
                    MyTextfield(
                      hintText: "Password (min 6 characters)",
                      obscureText: true,
                      controller: passwordController,
                    ),
                    const SizedBox(height: 15),

                    // confirm password field
                    MyTextfield(
                      hintText: "Confirm password",
                      obscureText: true,
                      controller: confirmPwController,
                    ),
                    const SizedBox(height: 30),

                    // register button
                    SizedBox(
                      width: double.infinity,
                      child: MyButton(
                        text: "Create Account",
                        onTap: registerUser,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // login redirect
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: prefs.getTextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            "Sign in here",
                            style: prefs.getTextStyle(
                              fontWeight: FontWeight.bold,
                              color: prefs.currentAccentColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // terms and privacy note
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "By creating an account, you agree to Nova's community guidelines and privacy practices.",
                        style: prefs.getTextStyle(
                          multiplier: 0.75, // 12/16
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
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
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPwController.dispose();
    super.dispose();
  }
}
