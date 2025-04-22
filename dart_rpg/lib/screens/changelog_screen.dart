import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/changelog_service.dart';
import '../utils/logging_service.dart';

/// A screen to display the changelog
class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  final ChangelogService _changelogService = ChangelogService();
  final LoggingService _logger = LoggingService();
  bool _isLoading = true;
  List<ChangelogVersion> _versions = [];
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadChangelog();
  }
  
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        // Extract version without build number (e.g., "1.2.3+45" -> "1.2.3")
        _currentVersion = packageInfo.version.split('+')[0];
      });
      _logger.info('Loaded app version: $_currentVersion', tag: 'ChangelogScreen');
    } catch (e) {
      _logger.error('Failed to load app info: $e', tag: 'ChangelogScreen');
      setState(() {
        _currentVersion = '0.0.2'; // Fallback to a default version if loading fails
      });
    }
  }

  Future<void> _loadChangelog() async {
    try {
      final versions = await _changelogService.getAllVersions();
      setState(() {
        _versions = versions;
        _isLoading = false;
      });
    } catch (e) {
      _logger.error('Failed to load changelog: $e', tag: 'ChangelogScreen');
      setState(() {
        _versions = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changelog'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _versions.isEmpty
              ? _buildEmptyState()
              : _buildChangelogList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_toggle_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No changelog entries found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back after the next update',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _versions.length,
      itemBuilder: (context, index) {
        final version = _versions[index];
        final isCurrentVersion = version.version == _currentVersion;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          color: isCurrentVersion 
              ? Theme.of(context).colorScheme.primaryContainer 
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Version ${version.version}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (isCurrentVersion)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      version.date,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...version.changes.map((change) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(change)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}
