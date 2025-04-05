import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/widgets/progress_box_painter.dart';
import 'package:dart_rpg/providers/settings_provider.dart';

class ProgressTrackWidget extends StatefulWidget {
  final String label;
  final int value; // Value in boxes (0-10)
  final int ticks; // Value in ticks (0-40)
  final int maxValue; // Max value in boxes
  final Function(int)? onBoxChanged; // Callback when box value changes
  final Function(int)? onTickChanged; // Callback when tick value changes
  final bool isEditable;
  final bool showTicks; // Whether to show ticks or just filled boxes

  const ProgressTrackWidget({
    super.key,
    required this.label,
    this.value = 0,
    this.ticks = 0,
    this.maxValue = 10,
    this.onBoxChanged,
    this.onTickChanged,
    this.isEditable = true,
    this.showTicks = true,
  });

  @override
  State<ProgressTrackWidget> createState() => _ProgressTrackWidgetState();
}

class _ProgressTrackWidgetState extends State<ProgressTrackWidget> 
    with SingleTickerProviderStateMixin {
  
  // Main animation controller for progress changes
  late AnimationController _animationController;
  late Animation<double> _boxAnimation;
  late Animation<double> _tickAnimation;
  
  // Glitch effect animation
  late Animation<double> _glitchAnimation;
  
  // Glow effect animation
  late Animation<double> _glowAnimation;
  
  // Track the previous values for animation
  late int _previousValue;
  late int _previousTicks;
  
  // Track which box was most recently filled
  int? _lastFilledBoxIndex;
  
  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _previousTicks = widget.ticks;
    
    // Get settings
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // Initialize animation controller with settings-aware duration
    _animationController = AnimationController(
      duration: settings.getAnimationDuration(const Duration(milliseconds: 450)),
      vsync: this,
    );
    
    // Initialize animations
    _boxAnimation = Tween<double>(
      begin: widget.value.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _tickAnimation = Tween<double>(
      begin: widget.ticks.toDouble(),
      end: widget.ticks.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Glitch effect animation - more intense at start, fades out
    _glitchAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      // Custom curve that peaks early and fades out
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutExpo),
    ));
    
    // Glow effect animation - builds up and fades out
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      // Glow builds up quickly, then fades out slowly
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));
  }
  
  @override
  void didUpdateWidget(ProgressTrackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Get settings
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // Check if values have changed
    if (oldWidget.value != widget.value || oldWidget.ticks != widget.ticks) {
      // If animations are disabled, just update the values immediately
      if (!settings.enableAnimations) {
        _previousValue = widget.value;
        _previousTicks = widget.ticks;
        _lastFilledBoxIndex = null;
        return;
      }
      
      // Determine which box was filled (for glow effect)
      if (widget.value > oldWidget.value) {
        // A new box was completely filled
        _lastFilledBoxIndex = oldWidget.value;
      } else if (widget.ticks > oldWidget.ticks && widget.ticks % 4 == 1) {
        // A new box started being filled
        _lastFilledBoxIndex = widget.value;
      } else {
        // No new box was filled
        _lastFilledBoxIndex = null;
      }
      
      // Update animations with new values
      _boxAnimation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      
      _tickAnimation = Tween<double>(
        begin: _previousTicks.toDouble(),
        end: widget.ticks.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      
      // Reset and start animation with updated duration
      _animationController.duration = settings.getAnimationDuration(const Duration(milliseconds: 450));
      _animationController.reset();
      _animationController.forward().then((_) {
        // Update previous values after animation completes
        _previousValue = widget.value;
        _previousTicks = widget.ticks;
        
        // Clear last filled box after animation
        setState(() {
          _lastFilledBoxIndex = null;
        });
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Calculate the number of ticks in a specific box based on animated values
  int _getTicksInBox(int boxIndex, double animatedBoxValue, double animatedTickValue) {
    if (boxIndex < animatedBoxValue.floor()) {
      return 4; // Full box
    } else if (boxIndex == animatedBoxValue.floor() && animatedTickValue.floor() % 4 > 0) {
      return animatedTickValue.floor() % 4; // Partially filled box
    } else {
      return 0; // Empty box
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).colorScheme.outline;
    
    // Cyberpunk glow color - neon blue
    final glowColor = Colors.cyan;
    
    // Get settings
    final settings = Provider.of<SettingsProvider>(context);
    
    // If animations are disabled, return static widget
    if (!settings.enableAnimations) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: List.generate(widget.maxValue, (index) {
                      final boxTicks = widget.showTicks 
                          ? _getTicksInBox(index, widget.value.toDouble(), widget.ticks.toDouble())
                          : (index < widget.value ? 4 : 0);
                      
                      final isHighlighted = widget.isEditable && 
                                          index == widget.value && 
                                          boxTicks < 4;
                      
                      return Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: GestureDetector(
                            onTap: widget.isEditable ? () {
                              // Existing tap handling code
                              if (widget.showTicks && widget.onTickChanged != null) {
                                // Calculate new tick value
                                int newTicks;
                                if (index < widget.value) {
                                  newTicks = index * 4 + 1;
                                } else if (index == widget.value) {
                                  int currentTicks = widget.ticks % 4;
                                  if (currentTicks < 4) {
                                    newTicks = (index * 4) + currentTicks + 1;
                                  } else {
                                    newTicks = (index + 1) * 4;
                                  }
                                } else {
                                  newTicks = index * 4 + 1;
                                }
                                widget.onTickChanged!(newTicks);
                              } else if (widget.onBoxChanged != null) {
                                widget.onBoxChanged!(index + 1);
                              }
                            } : null,
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              child: widget.showTicks
                                  ? CustomPaint(
                                      painter: ProgressBoxPainter(
                                        ticks: boxTicks,
                                        boxColor: backgroundColor,
                                        tickColor: primaryColor,
                                        borderColor: borderColor,
                                        isHighlighted: isHighlighted,
                                        glowIntensity: 0.0, // No glow when animations disabled
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: boxTicks == 4
                                            ? primaryColor
                                            : backgroundColor,
                                        border: Border.all(color: borderColor, width: 2.0),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${widget.value}/${widget.maxValue}'),
            ],
          ),
        ],
      );
    }
    
    // Otherwise, return animated widget
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Calculate animated values
                    final animatedBoxValue = _boxAnimation.value;
                    final animatedTickValue = _tickAnimation.value;
                    
                    // Calculate glitch effect
                    final glitchIntensity = _glitchAnimation.value;
                    final glitchOffset = sin(_animationController.value * 15) * 
                                        glitchIntensity * 
                                        2.0; // Max 2 pixels offset
                    
                    // Apply glitch effect during animation
                    return Transform.translate(
                      offset: Offset(glitchOffset, 0),
                      child: Row(
                        children: List.generate(widget.maxValue, (index) {
                          // Calculate ticks for this box based on animated values
                          int boxTicks;
                          if (widget.showTicks) {
                            boxTicks = _getTicksInBox(index, animatedBoxValue, animatedTickValue);
                          } else {
                            boxTicks = index < animatedBoxValue.floor() ? 4 : 0;
                          }
                          
                          final isHighlighted = widget.isEditable && 
                                              index == animatedBoxValue.floor() && 
                                              boxTicks < 4;
                          
                          // Determine if this box should glow
                          final shouldGlow = _lastFilledBoxIndex != null && 
                                           index == _lastFilledBoxIndex;
                          
                          // Calculate glow intensity
                          final glowIntensity = shouldGlow ? _glowAnimation.value : 0.0;
                          
                          return Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: GestureDetector(
                                onTap: widget.isEditable ? () {
                                  // Existing tap handling code
                                  if (widget.showTicks && widget.onTickChanged != null) {
                                    // Calculate new tick value
                                    int newTicks;
                                    if (index < widget.value) {
                                      newTicks = index * 4 + 1;
                                    } else if (index == widget.value) {
                                      int currentTicks = widget.ticks % 4;
                                      if (currentTicks < 4) {
                                        newTicks = (index * 4) + currentTicks + 1;
                                      } else {
                                        newTicks = (index + 1) * 4;
                                      }
                                    } else {
                                      newTicks = index * 4 + 1;
                                    }
                                    widget.onTickChanged!(newTicks);
                                  } else if (widget.onBoxChanged != null) {
                                    widget.onBoxChanged!(index + 1);
                                  }
                                } : null,
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  // Add glow effect with Container decoration
                                  decoration: shouldGlow ? BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: glowColor.withAlpha((glowIntensity * 0.7 * 255).toInt()),
                                        blurRadius: 8.0 * glowIntensity,
                                        spreadRadius: 2.0 * glowIntensity,
                                      ),
                                    ],
                                  ) : null,
                                  child: widget.showTicks
                                      ? CustomPaint(
                                          painter: ProgressBoxPainter(
                                            ticks: boxTicks,
                                            boxColor: backgroundColor,
                                            tickColor: shouldGlow 
                                                ? Color.lerp(primaryColor, glowColor, glowIntensity)!
                                                : primaryColor,
                                            borderColor: shouldGlow 
                                                ? Color.lerp(borderColor, glowColor, glowIntensity)!
                                                : borderColor,
                                            isHighlighted: isHighlighted,
                                            glowIntensity: glowIntensity,
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: boxTicks == 4
                                                ? shouldGlow 
                                                    ? Color.lerp(primaryColor, glowColor, glowIntensity)
                                                    : primaryColor
                                                : backgroundColor,
                                            border: Border.all(
                                              color: shouldGlow 
                                                  ? Color.lerp(borderColor, glowColor, glowIntensity)!
                                                  : borderColor, 
                                              width: 2.0
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _boxAnimation,
              builder: (context, child) {
                return Text('${_boxAnimation.value.round()}/${widget.maxValue}');
              },
            ),
          ],
        ),
      ],
    );
  }
}
