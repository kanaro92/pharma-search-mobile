import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'pharmacist_home_screen.dart';
import 'login_screen.dart';

class RoleBasedMainScreen extends StatefulWidget {
  final ApiService apiService;

  const RoleBasedMainScreen({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  State<RoleBasedMainScreen> createState() => _RoleBasedMainScreenState();
}

class _RoleBasedMainScreenState extends State<RoleBasedMainScreen> {
  bool _checkedRole = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    if (_checkedRole) return;

    final role = await UserService().getUserRole();
    if (!mounted) return;

    setState(() {
      _checkedRole = true;
      _userRole = role;
    });

    if (role == null) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _navigateToPharmacist() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PharmacistHomeScreen(apiService: widget.apiService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // After role check, navigate based on role
    if (_userRole == null) {
      return const LoginScreen();
    } else if (_userRole == 'PHARMACIST') {
      return PharmacistHomeScreen(apiService: widget.apiService);
    } else {
      return HomeScreen(apiService: widget.apiService);
    }
  }
}
