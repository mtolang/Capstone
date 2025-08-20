import 'package:flutter/material.dart';
import 'package:capstone_2/helper/auth.dart';

class AuthTestPage extends StatefulWidget {
  const AuthTestPage({Key? key}) : super(key: key);

  @override
  State<AuthTestPage> createState() => _AuthTestPageState();
}

class _AuthTestPageState extends State<AuthTestPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    if (!_isLogin && _nameController.text.isEmpty) {
      _showMessage('Please enter your name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await AuthService.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        _showMessage('Login successful!');
      } else {
        await AuthService.registerWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );
        _showMessage('Registration successful!');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login Test' : 'Register Test'),
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (!_isLogin) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A5B),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isLogin ? 'Login' : 'Register'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(
                _isLogin
                    ? "Don't have an account? Register"
                    : "Already have an account? Login",
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder(
              stream: AuthService.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    children: [
                      Text('Logged in as: ${snapshot.data?.email}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await AuthService.signOut();
                          _showMessage('Logged out successfully');
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                }
                return const Text('Not logged in');
              },
            ),
          ],
        ),
      ),
    );
  }
}
