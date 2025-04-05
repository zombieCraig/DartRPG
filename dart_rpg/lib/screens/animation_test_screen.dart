import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/progress_track_widget.dart';
import '../providers/settings_provider.dart';

/// A test screen to demonstrate the progress track animations.
class AnimationTestScreen extends StatefulWidget {
  const AnimationTestScreen({super.key});

  @override
  State<AnimationTestScreen> createState() => _AnimationTestScreenState();
}

class _AnimationTestScreenState extends State<AnimationTestScreen> {
  int _progressValue = 0;
  int _progressTicks = 0;
  
  void _incrementProgress() {
    setState(() {
      if (_progressTicks < 40) {
        _progressTicks += 1;
        _progressValue = _progressTicks ~/ 4;
      }
    });
  }
  
  void _decrementProgress() {
    setState(() {
      if (_progressTicks > 0) {
        _progressTicks -= 1;
        _progressValue = _progressTicks ~/ 4;
      }
    });
  }
  
  void _resetProgress() {
    setState(() {
      _progressValue = 0;
      _progressTicks = 0;
    });
  }
  
  void _fillProgress() {
    setState(() {
      _progressTicks = 40;
      _progressValue = 10;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Test'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Container(
        color: Colors.blueGrey[900], // Dark background for cyberpunk feel
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress Track Animation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progress track with animations
                ProgressTrackWidget(
                  label: 'Quest Progress',
                  value: _progressValue,
                  ticks: _progressTicks,
                  maxValue: 10,
                  onTickChanged: (ticks) {
                    setState(() {
                      _progressTicks = ticks;
                      _progressValue = ticks ~/ 4;
                    });
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _decrementProgress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Decrease'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _incrementProgress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Increase'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _resetProgress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _fillProgress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Fill'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Current progress display
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.cyan,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'Progress: $_progressValue boxes, $_progressTicks ticks',
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 18,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Animation settings
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.cyan,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Animation Settings',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Enable animations toggle
                          SwitchListTile(
                            title: const Text(
                              'Enable Animations',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: settings.enableAnimations,
                            activeColor: Colors.cyan,
                            onChanged: (value) {
                              settings.setEnableAnimations(value);
                            },
                          ),
                          
                          // Only show these options if animations are enabled
                          if (settings.enableAnimations) ...[
                            // Animation speed slider
                            ListTile(
                              title: const Text(
                                'Animation Speed',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Slider(
                                min: 0.5,
                                max: 2.0,
                                divisions: 6,
                                label: '${settings.animationSpeed.toStringAsFixed(1)}x',
                                value: settings.animationSpeed,
                                activeColor: Colors.cyan,
                                onChanged: (value) {
                                  settings.setAnimationSpeed(value);
                                },
                              ),
                              trailing: Text(
                                '${settings.animationSpeed.toStringAsFixed(1)}x',
                                style: const TextStyle(
                                  color: Colors.cyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            
                            // Glitch effects toggle
                            SwitchListTile(
                              title: const Text(
                                'Glitch Effects',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: settings.enableGlitchEffects,
                              activeColor: Colors.cyan,
                              onChanged: (value) {
                                settings.setEnableGlitchEffects(value);
                              },
                            ),
                            
                            // Glow effects toggle
                            SwitchListTile(
                              title: const Text(
                                'Glow Effects',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: settings.enableGlowEffects,
                              activeColor: Colors.cyan,
                              onChanged: (value) {
                                settings.setEnableGlowEffects(value);
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Use the Increase/Decrease buttons to change progress\n'
                        '• Use Reset to set progress to 0\n'
                        '• Use Fill to set progress to maximum\n'
                        '• You can also tap directly on the progress boxes\n'
                        '• Adjust animation settings to see different effects',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
