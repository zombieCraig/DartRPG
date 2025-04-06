import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/circuit_reveal_animation.dart';
import '../widgets/digital_blocks_animation.dart';
import '../widgets/matrix_rain_animation.dart';
import 'transition_type.dart';

/// A service for handling navigation with custom transitions
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  
  factory NavigationService() => _instance;
  
  NavigationService._internal();
  
  /// Get a page route with the appropriate transition
  PageRoute<T> getPageRoute<T>({
    required Widget page,
    required BuildContext context,
    TransitionType? transitionType,
    String? routeName,
  }) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // If animations are disabled, use default route
    if (!settings.enableAnimations) {
      return MaterialPageRoute<T>(
        builder: (_) => page,
        settings: RouteSettings(name: routeName),
      );
    }
    
    // Get transition duration based on animation speed
    final duration = settings.getAnimationDuration(
      const Duration(milliseconds: 400),
    );
    
    // Use specified transition type or default from settings
    final type = transitionType ?? settings.transitionType;
    
    switch (type) {
      case TransitionType.glitch:
        return _createGlitchRoute<T>(
          page: page, 
          duration: duration,
          enableGlitch: settings.enableGlitchEffects,
          routeName: routeName,
        );
      case TransitionType.cyberSlide:
        return _createCyberSlideRoute<T>(
          page: page, 
          duration: duration,
          routeName: routeName,
        );
      case TransitionType.hackerFade:
        return _createHackerFadeRoute<T>(
          page: page, 
          duration: duration,
          routeName: routeName,
        );
      case TransitionType.digitalWipe:
        return _createDigitalWipeRoute<T>(
          page: page, 
          duration: duration,
          routeName: routeName,
        );
      case TransitionType.terminalBoot:
        return _createTerminalBootRoute<T>(
          page: page, 
          duration: duration,
          routeName: routeName,
        );
      case TransitionType.circuitReveal:
        return _createCircuitRevealRoute<T>(
          page: page, 
          duration: duration,
          routeName: routeName,
        );
      case TransitionType.none:
      default:
        return MaterialPageRoute<T>(
          builder: (_) => page,
          settings: RouteSettings(name: routeName),
        );
    }
  }
  
  /// Navigate to a new screen with a custom transition
  Future<T?> navigateTo<T>(
    BuildContext context,
    Widget page, {
    TransitionType? transitionType,
    String? routeName,
  }) {
    return Navigator.push<T>(
      context,
      getPageRoute<T>(
        page: page,
        context: context,
        transitionType: transitionType,
        routeName: routeName,
      ),
    );
  }
  
  /// Replace the current screen with a new one using a custom transition
  Future<T?> replaceWith<T>(
    BuildContext context,
    Widget page, {
    TransitionType? transitionType,
    String? routeName,
  }) {
    return Navigator.pushReplacement<T, dynamic>(
      context,
      getPageRoute<T>(
        page: page,
        context: context,
        transitionType: transitionType,
        routeName: routeName,
      ),
    );
  }
  
  /// Go back to the previous screen
  void goBack<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }
  
  // Private methods to create each type of route
  
  PageRoute<T> _createGlitchRoute<T>({
    required Widget page,
    required Duration duration,
    bool enableGlitch = true,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Base fade transition
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        
        // Glitch intensity animation - more intense in the middle
        final glitchIntensity = enableGlitch 
          ? Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
              ),
            )
          : const AlwaysStoppedAnimation<double>(0.0);
        
        return AnimatedBuilder(
          animation: Listenable.merge([animation, glitchIntensity]),
          builder: (context, _) {
            // Calculate glitch effect values
            final double glitchAmount = enableGlitch ? glitchIntensity.value * 0.5 : 0.0;
            final double offsetX = sin(animation.value * 15) * glitchAmount * 10.0;
            final double skewX = sin(animation.value * 10) * glitchAmount * 0.1;
            
            return Opacity(
              opacity: fadeAnimation.value,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateX(sin(animation.value * 5) * glitchAmount * 0.05)
                  ..rotateY(skewX)
                  ..translate(offsetX),
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
        );
      },
    );
  }
  
  PageRoute<T> _createCyberSlideRoute<T>({
    required Widget page,
    required Duration duration,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide animation
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        
        // Digital effect animation
        final digitalEffect = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
        ));
        
        return SlideTransition(
          position: slideAnimation,
          child: AnimatedBuilder(
            animation: digitalEffect,
            builder: (context, _) {
              final effectValue = digitalEffect.value;
              
              // Apply digital effect only during transition
              if (effectValue < 1.0) {
                return ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.8),
                        Colors.white,
                      ],
                      stops: [
                        0.0,
                        0.5 + sin(animation.value * 20) * 0.1,
                        1.0,
                      ],
                    ).createShader(bounds);
                  },
                  child: child,
                );
              } else {
                return child;
              }
            },
          ),
        );
      },
    );
  }
  
  PageRoute<T> _createHackerFadeRoute<T>({
    required Widget page,
    required Duration duration,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade animation for the content
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));
        
        // Matrix effect animation - stays visible throughout
        final matrixEffect = Tween<double>(
          begin: 0.7,  // Start with high intensity
          end: 0.3,    // Fade to lower intensity at the end
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
        ));
        
        return Stack(
          children: [
            // Black background to ensure contrast
            Positioned.fill(
              child: Container(color: Colors.black),
            ),
            
            // Matrix-style falling characters effect - always visible during transition
            Positioned.fill(
              child: MatrixRainAnimation(
                opacity: matrixEffect.value,
                color: Colors.green,
                speed: 1.5,
                useComplexChars: true,
              ),
            ),
            
            // Main content with fade in
            Opacity(
              opacity: fadeAnimation.value,
              child: child,
            ),
          ],
        );
      },
    );
  }
  
  
  PageRoute<T> _createDigitalWipeRoute<T>({
    required Widget page,
    required Duration duration,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Digital wipe animation
        final wipeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));
        
        // Content reveal animation
        final contentAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ));
        
        return AnimatedBuilder(
          animation: Listenable.merge([wipeAnimation, contentAnimation]),
          builder: (context, _) {
            return Stack(
              children: [
                // Digital blocks animation
                Positioned.fill(
                  child: DigitalBlocksAnimation(
                    progress: wipeAnimation.value,
                    direction: DigitalWipeDirection.leftToRight,
                    color: Colors.cyan,
                    blockSize: 12.0,
                    density: 1.2,
                  ),
                ),
                
                // Content with reveal effect
                Opacity(
                  opacity: contentAnimation.value,
                  child: child,
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  PageRoute<T> _createTerminalBootRoute<T>({
    required Widget page,
    required Duration duration,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Terminal boot animation
        final bootAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
        ));
        
        return AnimatedBuilder(
          animation: bootAnimation,
          builder: (context, _) {
            // Terminal boot effect
            if (bootAnimation.value < 0.9) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (bootAnimation.value > 0.1)
                        const Text(
                          'Initializing system...',
                          style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (bootAnimation.value > 0.3)
                        const Text(
                          'Loading modules...',
                          style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (bootAnimation.value > 0.5)
                        const Text(
                          'Establishing connection...',
                          style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (bootAnimation.value > 0.7)
                        const Text(
                          'System ready.',
                          style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            } else {
              // Fade in the actual page at the end
              return Opacity(
                opacity: (bootAnimation.value - 0.9) * 10, // 0.9-1.0 mapped to 0-1
                child: child,
              );
            }
          },
        );
      },
    );
  }
  
  PageRoute<T> _createCircuitRevealRoute<T>({
    required Widget page,
    required Duration duration,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Circuit reveal animation
        final revealAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));
        
        // Content fade animation
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ));
        
        return AnimatedBuilder(
          animation: Listenable.merge([revealAnimation, fadeAnimation]),
          builder: (context, _) {
            return Stack(
              children: [
                // Circuit board pattern animation
                Positioned.fill(
                  child: CircuitRevealAnimation(
                    progress: revealAnimation.value,
                    color: Colors.cyanAccent,
                    direction: CircuitRevealDirection.centerOut,
                    density: 1.2,
                  ),
                ),
                
                // Content with fade in
                Opacity(
                  opacity: fadeAnimation.value,
                  child: child,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Helper function to calculate sine
double sin(double value) {
  return (value - value.truncate()) * 2 - 1;
}
