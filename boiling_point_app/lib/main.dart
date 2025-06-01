import 'package:boiling_point_app/screens/home_screen.dart';
import 'package:boiling_point_app/screens/login_screen.dart';
import 'package:boiling_point_app/screens/signup_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(BoilingPointApp());
}

class BoilingPointApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(), // Add this line
      },
    );
  }
}
