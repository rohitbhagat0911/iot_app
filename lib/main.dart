import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ituyexfukeapaztoafdy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0dXlleGZ1a2VhcGF6dG9hZmR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5OTQ0OTksImV4cCI6MjA3MDU3MDQ5OX0.X5_9P5NzxwsPJ9WmGILPPp5fflFbdaCAeABicHROslU',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

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
      home: const MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _userId;
  bool _isSignedIn = false;
  String _statusMessage = 'Not signed in';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((event) {
      setState(() {
        _userId = event.session?.user.id;
        _isSignedIn = event.session != null;
        if (_isSignedIn) {
          _statusMessage = 'Successfully signed in';
        }
      });
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing in...';
    });

    try {
      const webClientId =
          '351698344205-sib7nbt78viq1lbhhlli8foj8vcma4lg.apps.googleusercontent.com';
      const iosClientId =
          '351698344205-um6cmo203vt4omah5i60leaqov1dlb6a.apps.googleusercontent.com';

      final GoogleSignIn signIn = GoogleSignIn.instance;

      unawaited(signIn.initialize(
          clientId: iosClientId, serverClientId: webClientId));

      final googleAccount = await signIn.authenticate();

      if (googleAccount == null) {
        setState(() {
          _statusMessage = 'Sign in canceled';
          _isLoading = false;
        });
        return;
      }

      final googleAuthorization =
          await googleAccount.authorizationClient.authorizationForScopes([]);
      final googleAuthentication = googleAccount.authentication;
      final idToken = googleAuthentication.idToken;
      final accessToken = googleAuthorization?.accessToken;

      if (idToken == null || accessToken == null) {
        setState(() {
          _statusMessage = 'Sign in failed: Missing tokens';
          _isLoading = false;
        });
        return;
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      setState(() {
        _isLoading = false;
      });
    } on GoogleSignInException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == GoogleSignInExceptionCode.canceled) {
          _statusMessage = 'Authentication canceled';
        } else {
          _statusMessage = 'Authentication error: ${e.toString()}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Authentication failed: $e';
      });
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    await GoogleSignIn.instance.signOut();
    setState(() {
      _statusMessage = 'Signed out';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                _isSignedIn ? Icons.check_circle : Icons.account_circle,
                size: 80,
                color: _isSignedIn ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 24),
              if (_userId != null)
                Text(
                  'User ID: $_userId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                )
              else
                const Text(
                  'No user signed in',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _isSignedIn
                      ? Colors.green
                      : _statusMessage.contains('canceled')
                          ? Colors.orange
                          : _statusMessage.contains('failed') ||
                                  _statusMessage.contains('error')
                              ? Colors.red
                              : Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_isSignedIn)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sign in or sign up using your Google account',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
