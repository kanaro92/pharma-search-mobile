import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/role_based_main_screen.dart';
import 'screens/my_inquiries_screen.dart';
import 'screens/medication_search_screen.dart';
import 'screens/nearby_pharmacies_screen.dart';
import 'screens/pharmacist_inquiries_screen.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'PharmaSearch',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return auth.isAuthenticated
                      ? RoleBasedMainScreen(apiService: apiService)
                      : const LoginScreen();
                },
              ),
          '/login': (context) => const LoginScreen(),
          '/my-inquiries': (context) => const MyInquiriesScreen(),
          '/medication-search': (context) => MedicationSearchScreen(apiService: apiService),
          '/nearby-pharmacies': (context) => NearbyPharmaciesScreen(apiService: apiService),
          '/pharmacist-inquiries': (context) => PharmacistInquiriesScreen(apiService: apiService),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
