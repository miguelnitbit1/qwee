import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AuthMiddleware extends StatelessWidget {
  final Widget child;
  final String redirectRoute;

  const AuthMiddleware({
    super.key,
    required this.child,
    this.redirectRoute = '/login',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!userProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              redirectRoute,
              (route) => false,
            );
          });
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}