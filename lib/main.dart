import 'package:flutter/material.dart';
import 'package:kaluu_Epreess_Cargo/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:kaluu_Epreess_Cargo/auths/auth_controller.dart';
import 'package:kaluu_Epreess_Cargo/auths/login.dart';
import 'package:kaluu_Epreess_Cargo/auths/register.dart';
import 'package:kaluu_Epreess_Cargo/screeens/screenNavigation.dart';
import 'package:kaluu_Epreess_Cargo/screeens/splash_screen.dart';

import 'package:kaluu_Epreess_Cargo/providers/theme_provider.dart';

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
          title: 'KALUU EXPRESS APP',
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
  @override
  void initState() {
    super.initState();
    // Initialize auth state
    Future.microtask(() {
      if (mounted) {
        Provider.of<AuthController>(context, listen: false).init();
      }
    });
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
