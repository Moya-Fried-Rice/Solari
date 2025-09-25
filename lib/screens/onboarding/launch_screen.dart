import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/user_preferences_service.dart';
import '../../core/services/vibration_service.dart';
import 'bluetooth_router_screen.dart';

/// Launch/splash screen that displays when the app first starts
class LaunchScreen extends StatefulWidget {
  /// Creates a launch screen
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }
  
  /// Check if onboarding has been completed
  Future<void> _checkOnboardingStatus() async {
    try {
      final hasCompletedOnboarding = await PreferencesService.hasCompletedOnboarding();
      _navigateToNextScreen(hasCompletedOnboarding);
    } catch (e) {
      _navigateToNextScreen(false);
    }
  }

  /// Navigate to the next screen after a delay
  void _navigateToNextScreen(bool hasCompletedOnboarding) {
    Future.delayed(AppConstants.splashScreenDuration, () async {
      // Provide haptic feedback before transition
      await VibrationService.mediumFeedback();
      
      if (mounted) {
        // Navigate to the bluetooth router screen (handles Bluetooth logic)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BluetoothRouterScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/solari-logo.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Solari',
                    style: TextStyle(
                      fontSize: AppConstants.titleFontSize * 2,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}