import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/logging_service.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final LoggingService _loggingService = LoggingService();
  int _selectedLogLevel = LoggingService.LEVEL_DEBUG;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = _loggingService.logs;
    final filteredLogs = logs.where((log) {
      // Filter by log level
      if (log.level < _selectedLogLevel) {
        return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return log.message.toLowerCase().contains(_searchQuery) ||
               (log.tag?.toLowerCase().contains(_searchQuery) ?? false) ||
               (log.error?.toString().toLowerCase().contains(_searchQuery) ?? false);
      }
      
      return true;
    }).toList();
    
    // Sort logs by timestamp (newest first)
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy All Logs',
            onPressed: () => _copyLogs(filteredLogs),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Logs',
            onPressed: () => _clearLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Logs',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Log Level:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _selectedLogLevel,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLogLevel = newValue;
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: LoggingService.LEVEL_DEBUG,
                      child: const Text('Debug'),
                    ),
                    DropdownMenuItem(
                      value: LoggingService.LEVEL_INFO,
                      child: const Text('Info'),
                    ),
                    DropdownMenuItem(
                      value: LoggingService.LEVEL_WARNING,
                      child: const Text('Warning'),
                    ),
                    DropdownMenuItem(
                      value: LoggingService.LEVEL_ERROR,
                      child: const Text('Error'),
                    ),
                  ],
                ),
                const Spacer(),
                Text('${filteredLogs.length} logs'),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(
                    child: Text('No logs found'),
                  )
                : ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return _buildLogItem(context, log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, LogEntry log) {
    Color levelColor;
    switch (log.level) {
      case LoggingService.LEVEL_DEBUG:
        levelColor = Colors.grey;
        break;
      case LoggingService.LEVEL_INFO:
        levelColor = Colors.blue;
        break;
      case LoggingService.LEVEL_WARNING:
        levelColor = Colors.orange;
        break;
      case LoggingService.LEVEL_ERROR:
        levelColor = Colors.red;
        break;
      default:
        levelColor = Colors.grey;
    }

    final timestamp = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () => _showLogDetails(context, log),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      log.levelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  if (log.tag != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        log.tag!,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                  ],
                  Text(
                    timestamp,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                log.message,
                style: const TextStyle(fontSize: 14.0),
              ),
              if (log.error != null) ...[
                const SizedBox(height: 4.0),
                Text(
                  'Error: ${log.error}',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetails(BuildContext context, LogEntry log) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Log Details - ${log.levelName}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Timestamp: ${log.timestamp}'),
                if (log.tag != null) ...[
                  const SizedBox(height: 8.0),
                  Text('Tag: ${log.tag}'),
                ],
                const SizedBox(height: 8.0),
                const Text(
                  'Message:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Text(log.message),
                if (log.error != null) ...[
                  const SizedBox(height: 8.0),
                  const Text(
                    'Error:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  Text('${log.error}'),
                ],
                if (log.stackTrace != null) ...[
                  const SizedBox(height: 8.0),
                  const Text(
                    'Stack Trace:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  Text('${log.stackTrace}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => _copyLogEntry(log),
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  void _copyLogs(List<LogEntry> logs) {
    final text = logs.map((log) => log.toString()).join('\n\n');
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
      ),
    );
  }

  void _copyLogEntry(LogEntry log) {
    Clipboard.setData(ClipboardData(text: log.toString()));
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log entry copied to clipboard'),
      ),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Logs'),
          content: const Text('Are you sure you want to clear all logs? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _loggingService.clearLogs();
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
