import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<String?>(
        future: UserService().getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final role = snapshot.data;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.local_pharmacy, size: 35, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'PharmaSearch',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome to PharmaSearch',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (role == 'USER') ...[
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Search Medications'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/medication-search');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_pharmacy),
                  title: const Text('Nearby Pharmacies'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/nearby-pharmacies');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('My Inquiries'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/my-inquiries');
                  },
                ),
              ],
              if (role == 'PHARMACIST') ...[
                ListTile(
                  leading: const Icon(Icons.local_pharmacy),
                  title: const Text('My Pharmacy'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to pharmacy management
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Medication Inquiries'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/pharmacist-inquiries');
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to profile
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Logout'),
                onTap: () async {
                  await Provider.of<AuthProvider>(context, listen: false).logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
