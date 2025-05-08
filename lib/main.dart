import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libmu/screens/auth/login_screen.dart';
import 'package:libmu/screens/home/home_screen.dart';
import 'package:libmu/services/auth_service.dart';
import 'package:libmu/providers/theme_provider.dart';
import 'package:libmu/theme/app_theme.dart';
import 'package:libmu/screens/splash_screen.dart';
import 'package:libmu/widgets/animated_gradient_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libmu/screens/admin/admin_screen.dart';
import 'package:libmu/screens/qr_scanner_screen.dart';
import 'package:libmu/screens/home/borrowed_books_screen.dart';
import 'package:libmu/screens/reading_lists/reading_lists_screen.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (kReleaseMode) {
    // Suppress all errors and warnings in release mode
    FlutterError.onError = (FlutterErrorDetails details) {
      // Do nothing, suppress errors
    };
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Library Management',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              return AnimatedGradientBackground(
                child: child!,
              );
            },
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/admin': (context) => const AdminScreen(),
              '/qr_scanner': (context) => const QRScannerScreen(),
              '/borrowed-books': (context) => const BorrowedBooksScreen(),
              '/reading-lists': (context) => const ReadingListsScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
} 