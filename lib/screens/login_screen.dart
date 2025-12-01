import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.graphic_eq, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  "ZOFIO",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Stream & Download Your Favorite Music",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 60),
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    if (auth.isLoggedIn) {
                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(
                              auth.user?.photoURL ?? '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Welcome, ${auth.user?.displayName}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("Continue to App"),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => auth.signOut(),
                            child: const Text(
                              "Sign Out",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    }

                    return ElevatedButton.icon(
                      onPressed: () async {
                        final user = await auth.signInWithGoogle();
                        if (user != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Successfully signed in!"),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: const Text("Sign in with Google"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (!Provider.of<AuthProvider>(context).isLoggedIn)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Continue as Guest",
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
