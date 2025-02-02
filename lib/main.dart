import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/role_based_main_screen.dart';
import 'screens/my_inquiries_screen.dart';
import 'screens/medication_search_screen.dart';
import 'screens/nearby_pharmacies_screen.dart';
import 'screens/pharmacist_inquiries_screen.dart';
import 'screens/pharmacy_management_screen.dart';
import 'screens/profile_screen.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';

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
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B8EB3),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF6B8EB3)),
            titleTextStyle: TextStyle(
              color: Color(0xFF6B8EB3),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
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
          '/pharmacy-management': (context) => PharmacyManagementScreen(apiService: apiService),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
