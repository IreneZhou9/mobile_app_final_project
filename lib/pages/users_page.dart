import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../components/my_back_button.dart';
import '../components/my_listtile.dart';
import '../helper/helper_function.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("Users").snapshots(),
        builder: (context, snapshot) {
          // error state
          if (snapshot.hasError) {
            displayMessageToUser("Something went wrong", context);
          }
          
          // loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // no data
          if (snapshot.data == null) {
            return const Text("No data");
          }

          // get all users
          final users = snapshot.data!.docs;

          return Column(
            children: [
              // back button
              const Padding(
                padding: EdgeInsets.only(top: 50.0, left: 25),
                child: Row(
                  children: [
                    MyBackButton(),
                  ],
                ),
              ),

              // users list
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.all(0),
                  itemBuilder: (context, index) {
                    // get user data
                    final user = users[index];
                    String username = user['username'];
                    String email = user['email'];

                    return MyListTile(
                      title: username,
                      subtitle: email,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
