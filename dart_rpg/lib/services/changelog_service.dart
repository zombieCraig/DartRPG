import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/logging_service.dart';

/// A model class representing a version in the changelog
class ChangelogVersion {
  final String version;
  final String date;
  final List<String> changes;
  
  ChangelogVersion({
    required this.version,
    required this.date,
    required this.changes,
  });
  
  factory ChangelogVersion.fromJson(Map<String, dynamic> json) {
    return ChangelogVersion(
      version: json['version'],
      date: json['date'],
      changes: List<String>.from(json['changes']),
    );
  }
}

/// Service for loading and parsing the changelog
class ChangelogService {
  static final ChangelogService _instance = ChangelogService._internal();
  final LoggingService _logger = LoggingService();
  
  List<ChangelogVersion> _versions = [];
  bool _isLoaded = false;
  
  /// Factory constructor to return the singleton instance
  factory ChangelogService() {
    return _instance;
  }
  
  ChangelogService._internal();
  
  /// Load the changelog from the assets
  Future<void> loadChangelog() async {
    if (_isLoaded) return;
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/changelog.json');
      final jsonData = json.decode(jsonString);
      
      _versions = (jsonData['versions'] as List)
          .map((v) => ChangelogVersion.fromJson(v))
          .toList();
      
      _isLoaded = true;
      _logger.info('Changelog loaded successfully', tag: 'ChangelogService');
    } catch (e) {
      _logger.error('Failed to load changelog: $e', tag: 'ChangelogService');
      _versions = [];
      _isLoaded = false;
    }
  }
  
  /// Get all versions in the changelog
  Future<List<ChangelogVersion>> getAllVersions() async {
    if (!_isLoaded) {
      await loadChangelog();
    }
    return _versions;
  }
  
  /// Get a specific version by its version number
  Future<ChangelogVersion?> getVersionByNumber(String versionNumber) async {
    if (!_isLoaded) {
      await loadChangelog();
    }
    
    try {
      return _versions.firstWhere(
        (v) => v.version == versionNumber,
      );
    } catch (e) {
      _logger.warning('Version $versionNumber not found in changelog', tag: 'ChangelogService');
      return null;
    }
  }
  
  /// Get the latest version in the changelog
  Future<ChangelogVersion?> getLatestVersion() async {
    if (!_isLoaded) {
      await loadChangelog();
    }
    
    if (_versions.isEmpty) {
      _logger.warning('No versions found in changelog', tag: 'ChangelogService');
      return null;
    }
    
    return _versions.first;
  }
}
