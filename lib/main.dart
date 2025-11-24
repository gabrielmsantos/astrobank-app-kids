import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/customer_model.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';
import 'config/app_config.dart';
import 'services/customer_service.dart';

void main() {
  runApp(const AstroBankKidsApp());
}

class AstroBankKidsApp extends StatefulWidget {
  const AstroBankKidsApp({super.key});

  @override
  State<AstroBankKidsApp> createState() => _AstroBankKidsAppState();
}

class _AstroBankKidsAppState extends State<AstroBankKidsApp> {
  Customer? _currentCustomer;
  bool _isAuthenticated = true;

  void _handleLoginSuccess(Customer customer) {
    setState(() {
      _currentCustomer = customer;
      _isAuthenticated = true;
    });
  }

  void _handleLogout() {
    setState(() {
      _isAuthenticated = false;
      _currentCustomer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstroBank Kids',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: AppColors.bgLight,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryPurple,
            side: const BorderSide(color: AppColors.primaryPurple),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: _isAuthenticated
          ? _buildHome()
          : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }

  Widget _buildHome() {
    return FutureBuilder<Customer>(
      future: CustomerService.getCustomerDetails(
        AppConfig.defaultCustomerId,
        AppConfig.defaultBankId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.8),
                    AppColors.primaryPurple,
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.8),
                    AppColors.primaryPurple,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading customer data',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (snapshot.hasData) {
          _currentCustomer = snapshot.data;
          return HomeScreen(
            initialCustomer: snapshot.data!,
            onLogout: _handleLogout,
          );
        } else {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.8),
                    AppColors.primaryPurple,
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'No customer data available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
