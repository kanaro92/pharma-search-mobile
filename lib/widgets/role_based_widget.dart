import 'package:flutter/material.dart';
import '../services/user_service.dart';

class RoleBasedWidget extends StatelessWidget {
  final Widget pharmacistBuilder;
  final Widget userBuilder;
  final Widget? loadingBuilder;
  final Widget? unauthorizedBuilder;

  const RoleBasedWidget({
    Key? key,
    required this.pharmacistBuilder,
    required this.userBuilder,
    this.loadingBuilder,
    this.unauthorizedBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: UserService().getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder ?? const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return unauthorizedBuilder ?? const Center(child: Text('Please log in'));
        }

        switch (snapshot.data) {
          case 'PHARMACIST':
            return pharmacistBuilder;
          case 'USER':
            return userBuilder;
          default:
            return unauthorizedBuilder ?? const Center(child: Text('Unauthorized'));
        }
      },
    );
  }
}
