import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/providers/settings_provider.dart';
import 'package:dart_rpg/widgets/clock_segment_painter.dart';
import 'package:dart_rpg/models/clock.dart';

class AnimatedClockWidget extends StatefulWidget {
  final String label;
  final int segments; // Total number of segments (4, 6, 8, or 10)
  final int filledSegments; // Number of filled segments
  final Color fillColor; // Color for filled segments
  final Color emptyColor; // Color for empty segments
  final Color borderColor; // Color for the border
  final Function(int)? onChanged; // Callback when filled segments change
  final bool isEditable; // Whether the clock can be edited by tapping

  const AnimatedClockWidget({
    super.key,
    required this.label,
    required this.segments,
    required this.filledSegments,
    required this.fillColor,
    required this.emptyColor,
    this.borderColor = Colors.black,
    this.onChanged,
    this.isEditable = true,
  });

  @override
  State<AnimatedClockWidget> createState() => _AnimatedClockWidgetState();
}

class _AnimatedClockWidgetState extends State<AnimatedClockWidget>
    with SingleTickerProviderStateMixin {
  
  // Main animation controller for segment changes
  late AnimationController _animationController;
  late Animation<double> _segmentAnimation;
  
  // Glitch effect animation
  late Animation<double> _glitchAnimation;
  
  // Glow effect animation
  late Animation<double> _glowAnimation;
  
  // Track the previous value for animation
  late int _previousFilledSegments;
  
  // Track which segment was most recently filled
  int? _lastFilledSegmentIndex;
  
  @override
  void initState() {
    super.initState();
    _previousFilledSegments = widget.filledSegments;
    
    // Get settings
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // Initialize animation controller with settings-aware duration
    _animationController = AnimationController(
      duration: settings.getAnimationDuration(const Duration(milliseconds: 450)),
      vsync: this,
    );
    
    // Initialize animations
    _segmentAnimation = Tween<double>(
      begin: widget.filledSegments.toDouble(),
      end: widget.filledSegments.toDouble(),
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
  void didUpdateWidget(AnimatedClockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Get settings
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // Check if values have changed
    if (oldWidget.filledSegments != widget.filledSegments) {
      // If animations are disabled, just update the values immediately
      if (!settings.enableAnimations) {
        _previousFilledSegments = widget.filledSegments;
        _lastFilledSegmentIndex = null;
        return;
      }
      
      // Determine which segment was filled (for glow effect)
      if (widget.filledSegments > oldWidget.filledSegments) {
        // A new segment was filled
        _lastFilledSegmentIndex = oldWidget.filledSegments;
      } else {
        // No new segment was filled or segments were removed
        _lastFilledSegmentIndex = null;
      }
      
      // Update animations with new values
      _segmentAnimation = Tween<double>(
        begin: _previousFilledSegments.toDouble(),
        end: widget.filledSegments.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      
      // Reset and start animation with updated duration
      _animationController.duration = settings.getAnimationDuration(const Duration(milliseconds: 800)); // Longer duration for more visible animation
      _animationController.reset();
      
      // Force a rebuild before starting animation to ensure initial state is visible
      setState(() {});
      
      // Use Future.delayed to ensure the setState has completed before starting animation
      Future.microtask(() {
        if (mounted) {
          _animationController.forward().then((_) {
            // Update previous values after animation completes
            _previousFilledSegments = widget.filledSegments;
            
            // Clear last filled segment after animation
            if (mounted) {
              setState(() {
                _lastFilledSegmentIndex = null;
              });
            }
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
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
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: GestureDetector(
                    onTap: widget.isEditable ? () {
                      // Handle tap to fill next segment
                      if (widget.onChanged != null) {
                        if (widget.filledSegments < widget.segments) {
                          widget.onChanged!(widget.filledSegments + 1);
                        } else {
                          widget.onChanged!(0); // Reset if full
                        }
                      }
                    } : null,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.borderColor,
                            width: 2.0,
                          ),
                        ),
                        child: CustomPaint(
                          painter: ClockSegmentPainter(
                            segments: widget.segments,
                            filledSegments: widget.filledSegments,
                            fillColor: widget.fillColor,
                            emptyColor: widget.emptyColor,
                            borderColor: widget.borderColor,
                            strokeWidth: 2.0,
                          ),
                        ),
                      ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${widget.filledSegments}/${widget.segments}'),
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
              child: AspectRatio(
                aspectRatio: 1.0,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Calculate animated values
                    final animatedSegments = _segmentAnimation.value;
                    
                    // Calculate glitch effect
                    final glitchIntensity = settings.enableGlitchEffects ? _glitchAnimation.value : 0.0;
                    final glitchOffset = sin(_animationController.value * 15) * 
                                        glitchIntensity * 
                                        2.0; // Max 2 pixels offset
                    
                    // Calculate rotation for glitch effect
                    final glitchRotation = sin(_animationController.value * 20) * 
                                          glitchIntensity * 
                                          0.01; // Max 0.01 radians (about 0.6 degrees)
                    
                    // Apply glitch effect during animation
                    return Transform(
                      transform: Matrix4.identity()
                        ..translate(glitchOffset, 0.0)
                        ..rotateZ(glitchRotation),
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: widget.isEditable ? () {
                          // Handle tap to fill next segment
                          if (widget.onChanged != null) {
                            if (widget.filledSegments < widget.segments) {
                              widget.onChanged!(widget.filledSegments + 1);
                            } else {
                              widget.onChanged!(0); // Reset if full
                            }
                          }
                        } : null,
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: settings.getAnimationDuration(const Duration(milliseconds: 300)),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.borderColor,
                                width: 2.0,
                              ),
                            ),
                            child: CustomPaint(
                              painter: ClockSegmentPainter(
                                segments: widget.segments,
                                filledSegments: animatedSegments.round(),
                                fillColor: widget.fillColor,
                                emptyColor: widget.emptyColor,
                                borderColor: widget.borderColor,
                                strokeWidth: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _segmentAnimation,
              builder: (context, child) {
                return Text('${_segmentAnimation.value.round()}/${widget.segments}');
              },
            ),
          ],
        ),
      ],
    );
  }
}
