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
  bool _showEmailAuth = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

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

  Future<void> _signInWithEmail() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing in...';
    });

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sign in failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sign in failed: $e';
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating account...';
    });

    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
        _statusMessage = 'Check your email to verify account';
      });
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sign up failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sign up failed: $e';
      });
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    await GoogleSignIn.instance.signOut();
    setState(() {
      _statusMessage = 'Signed out';
      _showEmailAuth = false;
      _emailController.clear();
      _passwordController.clear();
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
          child: _isSignedIn
              ? _buildSignedInView()
              : _showEmailAuth
                  ? _buildEmailAuthView()
                  : _buildSignInOptionsView(),
        ),
      ),
    );
  }

  Widget _buildSignedInView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        if (_userId != null)
          Text(
            'User ID: $_userId',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        Text(
          _statusMessage,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailAuthView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Email Authentication',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 24),
          if (_statusMessage != 'Not signed in' &&
              !_statusMessage.contains('Signing') &&
              !_statusMessage.contains('Creating'))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _statusMessage.contains('failed') ||
                          _statusMessage.contains('error')
                      ? Colors.red
                      : Colors.orange,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_isSignUp ? _signUpWithEmail : _signInWithEmail),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _statusMessage = 'Not signed in';
                    });
                  },
            child: Text(
              _isSignUp
                  ? 'Already have an account? Sign In'
                  : "Don't have an account? Sign Up",
              style: const TextStyle(
                color: Colors.deepPurple,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _showEmailAuth = false;
                      _statusMessage = 'Not signed in';
                    });
                  },
            child: const Text('Back to Sign In Options'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInOptionsView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.account_circle,
          size: 80,
          color: Colors.grey,
        ),
        const SizedBox(height: 24),
        const Text(
          'No user signed in',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Text(
          _statusMessage,
          style: TextStyle(
            color: _statusMessage.contains('canceled')
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sign in or sign up using your Google account',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _showEmailAuth = true;
                    _statusMessage = 'Not signed in';
                  });
                },
          icon: const Icon(Icons.email),
          label: const Text('Continue with Email'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sign in or sign up using email and password',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
