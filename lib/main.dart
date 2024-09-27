import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_con_database_9624/ExpenseTracker.dart';
import 'package:flutter_con_database_9624/screen/screen_Signin.dart';
import 'todo.dart'; // Import the TodoApp widget
import 'firebase_options.dart'; // Import your Firebase configuration

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const SigninScreen(), // Set TodoApp as the home screen
    );
  }
}
