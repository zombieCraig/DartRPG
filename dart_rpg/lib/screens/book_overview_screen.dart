import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// A screen to display the Fe-Runners Book Overview markdown document
class BookOverviewScreen extends StatefulWidget {
  const BookOverviewScreen({super.key});

  @override
  State<BookOverviewScreen> createState() => _BookOverviewScreenState();
}

class _BookOverviewScreenState extends State<BookOverviewScreen> {
  String _markdownContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarkdownContent();
  }

  Future<void> _loadMarkdownContent() async {
    try {
      final String content = await rootBundle.loadString('assets/docs/overview.md');
      setState(() {
        _markdownContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _markdownContent = 'Error loading content: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fe-Runners Book Overview'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Markdown(
                data: _markdownContent,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: TextStyle(
                    fontSize: settingsProvider.fontSize,
                    fontFamily: settingsProvider.fontFamily,
                  ),
                  h1: TextStyle(
                    fontSize: settingsProvider.fontSize * 1.8,
                    fontWeight: FontWeight.bold,
                    fontFamily: settingsProvider.fontFamily,
                  ),
                  h2: TextStyle(
                    fontSize: settingsProvider.fontSize * 1.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: settingsProvider.fontFamily,
                  ),
                  h3: TextStyle(
                    fontSize: settingsProvider.fontSize * 1.3,
                    fontWeight: FontWeight.bold,
                    fontFamily: settingsProvider.fontFamily,
                  ),
                  h4: TextStyle(
                    fontSize: settingsProvider.fontSize * 1.2,
                    fontWeight: FontWeight.bold,
                    fontFamily: settingsProvider.fontFamily,
                  ),
                  h5: TextStyle(
                    fontSize: settingsProvider.fontSize * 1.1,
                    fontWeight: FontWeight.bold,
                    fontFamily: settingsProvider.fontFamily,
                  ),
                  h6: TextStyle(
                    fontSize: settingsProvider.fontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: settingsProvider.fontFamily,
                  ),
                  listBullet: TextStyle(
                    fontSize: settingsProvider.fontSize,
                    fontFamily: settingsProvider.fontFamily,
                  ),
                ),
                selectable: true,
              ),
            ),
    );
  }
}
