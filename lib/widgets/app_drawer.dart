import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../screens/login_screen.dart';
import '../l10n/app_localizations.dart';

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
                      AppLocalizations.get('welcome'),
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
                  title: Text(AppLocalizations.get('searchMedications')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/medication-search');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_pharmacy),
                  title: Text(AppLocalizations.get('nearbyPharmacies')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/nearby-pharmacies');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(AppLocalizations.get('myInquiries')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/my-inquiries');
                  },
                ),
              ],
              if (role == 'PHARMACIST') ...[
                ListTile(
                  leading: const Icon(Icons.local_pharmacy),
                  title: Text(AppLocalizations.get('myPharmacy')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/pharmacy-management');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: Text(AppLocalizations.get('medicationInquiries')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/pharmacist-inquiries');
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(AppLocalizations.get('profile')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(AppLocalizations.get('logout')),
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<AuthProvider>().logout();
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
