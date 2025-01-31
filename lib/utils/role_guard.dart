import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../screens/login_screen.dart';

class RoleGuard extends StatefulWidget {
  final String requiredRole;
  final Widget child;

  const RoleGuard({
    Key? key,
    required this.requiredRole,
    required this.child,
  }) : super(key: key);

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _checkedRole = false;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    if (_checkedRole) return;
    
    final userRole = await UserService().getUserRole();
    if (mounted) {
      setState(() {
        _checkedRole = true;
        _hasAccess = userRole == widget.requiredRole;
      });

      if (!_hasAccess) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
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

    if (!_hasAccess) {
      return const SizedBox.shrink();
    }

    return widget.child;
  }
}

// Extension method to easily check roles
extension RoleCheckExtension on BuildContext {
  Future<bool> hasRole(String role) async {
    final userRole = await UserService().getUserRole();
    return userRole == role;
  }
}
