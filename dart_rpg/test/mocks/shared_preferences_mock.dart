import 'package:shared_preferences/shared_preferences.dart';

/// Sets up mock values for SharedPreferences for testing
void setupSharedPreferencesMock() {
  // Set up mock values for SharedPreferences
  SharedPreferences.setMockInitialValues({
    'isDarkMode': false,
    'fontSize': 16.0,
    'fontFamily': 'Roboto',
    'logLevel': 0,
    'enableTutorials': true,
    'enableAnimations': true,
    'animationSpeed': 1.0,
    'enableGlitchEffects': false,
    'enableGlowEffects': false,
    'transitionType': 'TransitionType.cyberSlide',
  });
}
