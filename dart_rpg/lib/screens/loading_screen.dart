import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/console_text_animation.dart';
import '../transitions/navigation_service.dart';
import 'game_screen.dart';
import '../utils/logging_service.dart';

class LoadingScreen extends StatefulWidget {
  final String gameId;
  final String? dataswornSource;
  final bool hasMainCharacter;

  const LoadingScreen({
    super.key,
    required this.gameId,
    this.dataswornSource,
    required this.hasMainCharacter,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _isDataswornLoaded = false;
  bool _isAnimationComplete = false;
  
  // Fixed messages based on whether there's a main character
  List<String> _fixedMessages = [];
  
  // Pool of boot messages to randomly select from
  List<String> _bootMessages = [];
  
  // Index of the next fixed message to display
  int _fixedMessageIndex = 0;
  
  // Number of boot messages displayed so far
  int _bootMessagesDisplayed = 0;
  
  // Maximum number of boot messages to display
  final int _maxBootMessages = 10;
  
  // Whether to show the "System ready." message
  bool _showSystemReady = false;
  
  // Whether "System ready." has been displayed
  bool _systemReadyDisplayed = false;
  
  // Whether all messages have been displayed
  bool _allMessagesDisplayed = false;
  
  final LoggingService _loggingService = LoggingService();
  
  @override
  void initState() {
    super.initState();
    _initBootSequence();
    
    // Schedule the loading after the build is complete to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDatasworn();
    });
  }
  
  void _initBootSequence() {
    // Initialize fixed messages based on whether there's a main character
    if (widget.hasMainCharacter) {
      // Boot sequence for existing game with main character
      _fixedMessages = [
        "Jacking in...",
        "User identified as <player's main character>.",
        "Loading Avatar...",
      ];
    } else {
      // Boot sequence for new game
      _fixedMessages = [
        "Jacking in...",
        "Unknown user...",
        "Can't identify Avatar...",
      ];
    }
    
    // Initialize pool of possible boot messages
    _bootMessages = [
      "Initializing system...",
      "Connecting to network...",
      "Loading protocols...",
      "Establishing secure connection...",
      "Scanning for threats...",
      "Loading user interface...",
      "Calibrating neural interface...",
      "Syncing with satellite uplink...",
      "Bypassing security protocols...",
      "Establishing VPN tunnel...",
      "Checking firmware version...",
      "Loading encryption modules...",
      "Initializing quantum processors...",
      "Verifying biometric data...",
      "Scanning for malware...",
      "Optimizing memory allocation...",
      "Loading AI subroutines...",
      "Establishing mesh network...",
      "Synchronizing distributed systems...",
      "Initializing virtual environment...",
      "Loading tactical overlays...",
      "Checking for system updates...",
      "Initializing augmented reality modules...",
      "Calibrating sensory inputs...",
      "Loading language packs...",
      "Initializing voice recognition...",
      "Configuring neural pathways...",
      "Analyzing threat patterns...",
      "Establishing darknet connections...",
      "Verifying cryptographic keys...",
      "Loading stealth protocols...",
      "Initializing combat subroutines...",
      "Scanning for surveillance...",
      "Establishing secure data channels...",
      "Loading hacking tools...",
    ];
    
    // Shuffle the boot messages
    _bootMessages.shuffle();
  }
  
  /// Get the next message to display in the console animation
  String? _getNextMessage() {
    // If "System ready." has already been displayed, don't show any more messages
    if (_systemReadyDisplayed) {
      return null;
    }
    
    // If there are fixed messages left, return the next one
    if (_fixedMessageIndex < _fixedMessages.length) {
      return _fixedMessages[_fixedMessageIndex++];
    }
    
    // Ensure at least 1 random boot message is displayed
    if (_bootMessagesDisplayed < 1) {
      _bootMessagesDisplayed++;
      return _bootMessages[(_bootMessagesDisplayed - 1) % _bootMessages.length];
    }
    
    // If we should show the "System ready." message and we've displayed at least one boot message
    if (_showSystemReady && _bootMessagesDisplayed >= 1) {
      // Mark that all messages have been displayed
      _allMessagesDisplayed = true;
      _systemReadyDisplayed = true;
      _loggingService.debug('Displaying System ready message', tag: 'LoadingScreen');
      return "System ready.";
    }
    
    // If we've displayed the maximum number of boot messages, check if Datasworn is loaded
    if (_bootMessagesDisplayed >= _maxBootMessages) {
      // If Datasworn is loaded, show the "System ready." message next
      if (_isDataswornLoaded) {
        _showSystemReady = true;
        return _getNextMessage();
      }
      
      // Otherwise, continue showing random boot messages by cycling through them
      _bootMessagesDisplayed++;
      return _bootMessages[(_bootMessagesDisplayed - 1) % _bootMessages.length];
    }
    
    // Return the next boot message
    _bootMessagesDisplayed++;
    return _bootMessages[(_bootMessagesDisplayed - 1) % _bootMessages.length];
  }
  
  /// Called when a message is fully displayed
  void _onMessageComplete() {
    // If Datasworn is loaded and we've displayed all fixed messages,
    // show the "System ready." message next
    if (_isDataswornLoaded && 
        _fixedMessageIndex >= _fixedMessages.length && 
        !_showSystemReady) {
      setState(() {
        _showSystemReady = true;
      });
    }
    
    // If we've displayed "System ready." message, mark animation as complete
    if (_allMessagesDisplayed) {
      _loggingService.debug('System ready message displayed, completing animation', tag: 'LoadingScreen');
      
      // Add a small delay before marking animation as complete
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _onAnimationComplete();
        }
      });
    }
  }
  
  Future<void> _loadDatasworn() async {
    _loggingService.debug('Starting background loading of Datasworn', tag: 'LoadingScreen');
    
    // Start a timer to track loading time
    final startTime = DateTime.now();
    
    if (widget.dataswornSource != null) {
      try {
        final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
        await dataswornProvider.loadDatasworn(widget.dataswornSource!);
        
        if (mounted) {
          // Calculate elapsed time
          final elapsedTime = DateTime.now().difference(startTime);
          
          // Ensure a minimum loading time of 3 seconds to allow animation to progress
          final minimumLoadingTime = const Duration(seconds: 3);
          if (elapsedTime < minimumLoadingTime) {
            _loggingService.debug('Waiting for minimum loading time', tag: 'LoadingScreen');
            await Future.delayed(minimumLoadingTime - elapsedTime);
          }
          
          setState(() {
            _isDataswornLoaded = true;
            
            // If we've displayed all fixed messages, show the "System ready." message next
            if (_fixedMessageIndex >= _fixedMessages.length && !_showSystemReady) {
              _showSystemReady = true;
            }
          });
          
          _loggingService.debug('Datasworn loaded successfully', tag: 'LoadingScreen');
          
          // Wait for animation to complete before navigating
          if (_isAnimationComplete) {
            _navigateToGameScreen();
          }
        }
      } catch (e) {
        _loggingService.error('Error loading Datasworn', tag: 'LoadingScreen', error: e);
        // Even if there's an error, we should still navigate to the game screen
        if (mounted && _isAnimationComplete) {
          _navigateToGameScreen();
        }
      }
    } else {
      // If there's no datasworn source, still ensure a minimum display time
      final minimumLoadingTime = const Duration(seconds: 3);
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < minimumLoadingTime) {
        await Future.delayed(minimumLoadingTime - elapsedTime);
      }
      
      // Mark as loaded
      if (mounted) {
        setState(() {
          _isDataswornLoaded = true;
          
          // If we've displayed all fixed messages, show the "System ready." message next
          if (_fixedMessageIndex >= _fixedMessages.length && !_showSystemReady) {
            _showSystemReady = true;
          }
        });
        
        // Wait for animation to complete before navigating
        if (_isAnimationComplete) {
          _navigateToGameScreen();
        }
      }
    }
  }
  
  void _onAnimationComplete() {
    _loggingService.debug('Console animation complete', tag: 'LoadingScreen');
    
    // Check if the widget is still mounted before updating state
    if (!mounted) {
      _loggingService.debug('Widget not mounted in onAnimationComplete', tag: 'LoadingScreen');
      return;
    }
    
    setState(() {
      _isAnimationComplete = true;
    });
    
    // If data is already loaded, navigate to game screen
    if (_isDataswornLoaded) {
      _navigateToGameScreen();
    }
  }
  
  void _navigateToGameScreen() {
    // Check if the widget is still mounted before navigating
    if (!mounted) {
      _loggingService.debug('Widget not mounted, skipping navigation', tag: 'LoadingScreen');
      return;
    }
    
    _loggingService.debug('Navigating to GameScreen', tag: 'LoadingScreen');
    
    // Check if there's a main character
    final initialTabIndex = widget.hasMainCharacter ? 0 : 1;
    
    // Use Future.microtask to ensure we're not in the middle of a build cycle
    Future.microtask(() {
      if (mounted) {
        final navigationService = NavigationService();
        navigationService.replaceWith(
          context,
          GameScreen(
            gameId: widget.gameId,
            initialTabIndex: initialTabIndex,
          ),
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Get the main character name and handle if available
    String? mainCharacterName;
    String? mainCharacterHandle;
    if (widget.hasMainCharacter) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final mainCharacter = gameProvider.currentGame?.mainCharacter;
      mainCharacterName = mainCharacter?.name;
      mainCharacterHandle = mainCharacter?.handle;
      
      // If handle is not set, use the getHandle method to get or generate one
      if (mainCharacterHandle == null || mainCharacterHandle.isEmpty) {
        mainCharacterHandle = mainCharacter?.getHandle();
      }
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ConsoleTextAnimation(
          getNextMessage: _getNextMessage,
          onMessageComplete: _onMessageComplete,
          typingSpeed: const Duration(milliseconds: 50),
          initialPause: const Duration(milliseconds: 1000),
          linePause: const Duration(milliseconds: 800),
          reducedPause: const Duration(milliseconds: 100),
          isLoadingComplete: _isDataswornLoaded,
          onComplete: _onAnimationComplete,
          mainCharacterName: mainCharacterName,
          mainCharacterHandle: mainCharacterHandle,
        ),
      ),
    );
  }
}
