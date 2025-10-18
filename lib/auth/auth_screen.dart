import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showEmailAuth = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String _statusMessage = 'Not signed in';

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

      setState(() => _isLoading = false);
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
      setState(() => _isLoading = false);
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sign in failed: ${e.message}';
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
        _statusMessage = 'Account created! You can now sign in.';
        _isSignUp = false;
        _emailController.clear();
        _passwordController.clear();
      });
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sign up failed: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: !_showEmailAuth
              ? _buildSignInOptionsView()
              : _buildEmailAuthView(),
        ),
      ),
    );
  }

  Widget _buildSignInOptionsView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.account_circle, size: 80, color: Colors.grey),
        const SizedBox(height: 24),
        const Text(
          'Welcome to IOT App',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        ),
      ],
    );
  }

  Widget _buildEmailAuthView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Email Authentication',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  color: _statusMessage.contains('failed')
                      ? Colors.red
                      : Colors.orange,
                ),
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
            onTap: () {
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
            onPressed: () {
              setState(() {
                _showEmailAuth = false;
                _statusMessage = 'Not signed in';
              });
            },
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}