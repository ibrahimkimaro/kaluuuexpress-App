import 'package:flutter/material.dart';
import 'package:kaluu_bozen_cargo/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:kaluu_bozen_cargo/auths/auth_controller.dart';
import 'package:kaluu_bozen_cargo/auths/login.dart';
import 'package:kaluu_bozen_cargo/auths/register.dart';
import 'package:kaluu_bozen_cargo/screeens/screenNavigation.dart';
import 'package:kaluu_bozen_cargo/screeens/splash_screen.dart';
import 'package:app_links/app_links.dart';
import 'package:kaluu_bozen_cargo/auths/reset_password_page.dart';
import 'dart:async';

import 'package:kaluu_bozen_cargo/providers/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(),
        ), // ← Creates AuthController
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Kaluu/Bozen Cargo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4), // Soft purple seed
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(
              0xFFF5F5F5,
            ), // Soft grey background
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(
                0xFFD0BCFF,
              ), // Lighter purple for dark mode
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(
              0xFF121212,
            ), // Dark gentle background
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            '/homePage': (context) => const HomeScreeenNav(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    // Initialize auth state
    Future.microtask(() {
      if (mounted) {
        Provider.of<AuthController>(context, listen: false).init();
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      // Ignore errors
    }

    // Listen for new links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // Expected format: kaluuapp://reset-password/{uid}/{token}
    if (uri.host == 'reset-password') {
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final uid = segments[0];
        final token = segments[1];

        // Navigate to reset password page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(uid: uid, token: token),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        if (authController.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authController.isAuthenticated) {
          return const HomeScreeenNav();
        } else {
          return const RegisterPage();
        }
      },
    );
  }
}
