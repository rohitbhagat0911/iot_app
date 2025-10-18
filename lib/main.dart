import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'dart:async';

import 'auth/auth_screen.dart';
// import './pages/home.dart';
import './pages/dashboard.dart';
import 'services/supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ituyexfukeapaztoafdy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0dXlleGZ1a2VhcGF6dG9hZmR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5OTQ0OTksImV4cCI6MjA3MDU3MDQ5OX0.X5_9P5NzxwsPJ9WmGILPPp5fflFbdaCAeABicHROslU',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IOT App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;
          if (session == null) return const AuthScreen();

          // To show your visual dashboard instead of HomeScreen:
          // final userName = supabase.auth.currentUser?.email?.split('@').first ?? 'User';
          // return DashboardPage(username: userName);

          return const DashboardPage();
        },
      ),
    );
  }
}