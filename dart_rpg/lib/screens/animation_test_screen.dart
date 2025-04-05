import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/progress_track_widget.dart';
import '../widgets/animated_clock_widget.dart';
import '../providers/settings_provider.dart';
import '../models/clock.dart';

/// A test screen to demonstrate the progress track animations.
class AnimationTestScreen extends StatefulWidget {
  const AnimationTestScreen({super.key});

  @override
  State<AnimationTestScreen> createState() => _AnimationTestScreenState();
}

class _AnimationTestScreenState extends State<AnimationTestScreen> {
  // Progress track state
  int _progressValue = 0;
  int _progressTicks = 0;
  
  // Clock state
  int _clockSegments = 6; // Default to 6 segments
  int _filledSegments = 0;
  ClockType _clockType = ClockType.campaign; // Default to Campaign
  
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
  
  void _incrementClock() {
    setState(() {
      if (_filledSegments < _clockSegments) {
        _filledSegments += 1;
      }
    });
  }
  
  void _decrementClock() {
    setState(() {
      if (_filledSegments > 0) {
        _filledSegments -= 1;
      }
    });
  }
  
  void _resetClock() {
    setState(() {
      _filledSegments = 0;
    });
  }
  
  void _fillClock() {
    setState(() {
      _filledSegments = _clockSegments;
    });
  }
  
  void _setClockType(ClockType? type) {
    if (type != null) {
      setState(() {
        _clockType = type;
      });
    }
  }
  
  void _setClockSegments(int? segments) {
    if (segments != null) {
      setState(() {
        _clockSegments = segments;
        // Adjust filled segments if needed
        if (_filledSegments > segments) {
          _filledSegments = segments;
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Test'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Container(
        color: Colors.blueGrey[900],
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Track Section
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
                
                const SizedBox(height: 48),
                const Divider(color: Colors.cyan, thickness: 1),
                const SizedBox(height: 32),
                
                // Clock Animation Section
                const Text(
                  'Clock Animation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Clock type and segment selectors
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ClockType>(
                        decoration: const InputDecoration(
                          labelText: 'Clock Type',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          filled: true,
                          fillColor: Colors.black45,
                        ),
                        dropdownColor: Colors.grey[850],
                        value: _clockType,
                        style: const TextStyle(color: Colors.white),
                        onChanged: _setClockType,
                        items: ClockType.values.map((type) {
                          return DropdownMenuItem<ClockType>(
                            value: type,
                            child: Row(
                              children: [
                                Icon(type.icon, color: type.color),
                                const SizedBox(width: 8),
                                Text(type.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Segments',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          filled: true,
                          fillColor: Colors.black45,
                        ),
                        dropdownColor: Colors.grey[850],
                        value: _clockSegments,
                        style: const TextStyle(color: Colors.white),
                        onChanged: _setClockSegments,
                        items: [4, 6, 8, 10].map((segments) {
                          return DropdownMenuItem<int>(
                            value: segments,
                            child: Text('$segments segments'),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Clock widget
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: AnimatedClockWidget(
                      label: '${_clockType.displayName} Clock',
                      segments: _clockSegments,
                      filledSegments: _filledSegments,
                      fillColor: _clockType.color,
                      emptyColor: Colors.black45,
                      borderColor: Colors.white70,
                      onChanged: (value) {
                        setState(() {
                          _filledSegments = value;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Clock control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _decrementClock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Decrease'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _incrementClock,
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
                      onPressed: _resetClock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _fillClock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Fill'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Current clock display
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _clockType.color,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'Clock: $_filledSegments/$_clockSegments segments filled',
                      style: TextStyle(
                        color: _clockType.color,
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
                        'Progress Track:',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Use the Increase/Decrease buttons to change progress\n'
                        '• Use Reset to set progress to 0\n'
                        '• Use Fill to set progress to maximum\n'
                        '• You can also tap directly on the progress boxes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Clock:',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Select clock type and number of segments from dropdowns\n'
                        '• Use the Increase/Decrease buttons to fill or empty segments\n'
                        '• Use Reset to clear all segments\n'
                        '• Use Fill to fill all segments\n'
                        '• You can also tap directly on the clock to fill segments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Animation Settings:',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Toggle animations on/off\n'
                        '• Adjust animation speed\n'
                        '• Enable/disable glitch effects\n'
                        '• Enable/disable glow effects',
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
