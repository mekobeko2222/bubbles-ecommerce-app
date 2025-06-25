import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart'; // Your app's home screen
import 'auth_screen.dart'; // IMPORT YOUR EXISTING AUTH SCREEN

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen for auth state changes
      builder: (context, snapshot) {
        // If the user is not logged in, show YOUR AuthScreen
        if (!snapshot.hasData) {
          return const AuthScreen(); // Directly return your AuthScreen
        }

        // User is logged in, navigate to the HomeScreen
        // Pass the user's email to HomeScreen (it expects it)
        return HomeScreen(userEmail: snapshot.data!.email ?? 'user@example.com');
      },
    );
  }
}
