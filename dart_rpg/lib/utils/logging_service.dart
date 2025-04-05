import 'package:flutter/foundation.dart';

/// A logging service for the application.
/// 
/// This service provides methods for logging messages at different levels
/// (debug, info, warning, error) and formats them with timestamps and
/// other relevant information.
class LoggingService {
  // Singleton instance
  static final LoggingService _instance = LoggingService._internal();
  
  // Factory constructor to return the singleton instance
  factory LoggingService() => _instance;
  
  // Private constructor
  LoggingService._internal();
  
  // Store logs in memory for viewing in the app
  final List<LogEntry> _logs = [];
  
  // Get all logs
  List<LogEntry> get logs => List.unmodifiable(_logs);
  
  // Clear logs
  void clearLogs() {
    _logs.clear();
  }
  
  // Log levels
  static const int levelDebug = 0;
  static const int levelInfo = 1;
  static const int levelWarning = 2;
  static const int levelError = 3;
  
  // Current log level (only log messages at this level or higher)
  int _currentLevel = kDebugMode ? levelDebug : levelInfo;
  
  // Set the current log level
  void setLogLevel(int level) {
    _currentLevel = level;
  }
  
  // Format a log message with timestamp and level
  String _formatLogMessage(String level, String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    final now = DateTime.now();
    final timestamp = '${now.year}-${_padZero(now.month)}-${_padZero(now.day)} '
        '${_padZero(now.hour)}:${_padZero(now.minute)}:${_padZero(now.second)}.${_padZero(now.millisecond, 3)}';
    final tagString = tag != null ? '[$tag] ' : '';
    final errorString = error != null ? '\nError: $error' : '';
    final stackTraceString = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    
    return '[$timestamp] $level: $tagString$message$errorString$stackTraceString';
  }
  
  // Pad a number with leading zeros
  String _padZero(int number, [int width = 2]) {
    return number.toString().padLeft(width, '0');
  }
  
  // Log a debug message
  void debug(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_currentLevel <= levelDebug) {
      final formattedMessage = _formatLogMessage('DEBUG', message, tag: tag, error: error, stackTrace: stackTrace);
      debugPrint(formattedMessage);
      _logs.add(LogEntry(
        level: levelDebug,
        levelName: 'DEBUG',
        message: message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  // Log an info message
  void info(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_currentLevel <= levelInfo) {
      final formattedMessage = _formatLogMessage('INFO', message, tag: tag, error: error, stackTrace: stackTrace);
      debugPrint(formattedMessage);
      _logs.add(LogEntry(
        level: levelInfo,
        levelName: 'INFO',
        message: message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  // Log a warning message
  void warning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_currentLevel <= levelWarning) {
      final formattedMessage = _formatLogMessage('WARNING', message, tag: tag, error: error, stackTrace: stackTrace);
      debugPrint(formattedMessage);
      _logs.add(LogEntry(
        level: levelWarning,
        levelName: 'WARNING',
        message: message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  // Log an error message
  void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_currentLevel <= levelError) {
      final formattedMessage = _formatLogMessage('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
      debugPrint(formattedMessage);
      _logs.add(LogEntry(
        level: levelError,
        levelName: 'ERROR',
        message: message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  // Log an exception with stack trace
  void exception(String message, dynamic exception, {String? tag, StackTrace? stackTrace}) {
    final trace = stackTrace ?? StackTrace.current;
    error(message, tag: tag, error: exception, stackTrace: trace);
  }
}

/// A class representing a log entry
class LogEntry {
  final int level;
  final String levelName;
  final String message;
  final String? tag;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  
  LogEntry({
    required this.level,
    required this.levelName,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });
  
  // Format the log entry as a string
  @override
  String toString() {
    final timestampStr = '${timestamp.year}-${_padZero(timestamp.month)}-${_padZero(timestamp.day)} '
        '${_padZero(timestamp.hour)}:${_padZero(timestamp.minute)}:${_padZero(timestamp.second)}.${_padZero(timestamp.millisecond, 3)}';
    final tagString = tag != null ? '[$tag] ' : '';
    final errorString = error != null ? '\nError: $error' : '';
    final stackTraceString = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    
    return '[$timestampStr] $levelName: $tagString$message$errorString$stackTraceString';
  }
  
  // Pad a number with leading zeros
  String _padZero(int number, [int width = 2]) {
    return number.toString().padLeft(width, '0');
  }
}
