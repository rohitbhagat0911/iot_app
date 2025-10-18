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
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;
          return session == null ? const AuthScreen() : const HomeScreen();
        },
      ),
    );
  }
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedTab = 'All Devices';
  List<Map<String, dynamic>> devices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final response =
            await supabase.from('devices').select().eq('user_id', userId);
        setState(() {
          devices = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading devices: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('IOT App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName !',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['All Devices', 'Home', 'Office', 'Others'].map((tab) {
                      final isSelected = selectedTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: FilterChip(
                          label: Text(tab),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => selectedTab = tab);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.devices,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No devices added yet'),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to Add Device screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Add Device screen coming soon'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Device'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.lightbulb,
                                  color: Colors.orange),
                              title: Text(device['device_name'] ?? 'Unknown'),
                              subtitle: Text(
                                'Type: ${device['product_type'] ?? 'N/A'}\nMAC: ${device['bluetooth_mac_address'] ?? 'N/A'}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Edit device coming soon'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Device screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Device screen coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
