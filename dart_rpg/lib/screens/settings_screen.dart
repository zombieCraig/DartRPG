import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Theme settings
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: settings.isDarkMode,
                onChanged: (value) {
                  settings.setDarkMode(value);
                },
              ),
              const Divider(),
              
              // Font size settings
              const Text(
                'Text',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Font Size'),
                subtitle: Slider(
                  min: 12,
                  max: 24,
                  divisions: 6,
                  label: settings.fontSize.toStringAsFixed(1),
                  value: settings.fontSize,
                  onChanged: (value) {
                    settings.setFontSize(value);
                  },
                ),
                trailing: Text(
                  '${settings.fontSize.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: settings.fontSize),
                ),
              ),
              
              // Font family settings
              ListTile(
                title: const Text('Font Family'),
                subtitle: DropdownButton<String>(
                  value: settings.fontFamily,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setFontFamily(newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Roboto',
                      child: Text('Roboto'),
                    ),
                    DropdownMenuItem(
                      value: 'OpenSans',
                      child: Text('Open Sans'),
                    ),
                    DropdownMenuItem(
                      value: 'Lato',
                      child: Text('Lato'),
                    ),
                    DropdownMenuItem(
                      value: 'Montserrat',
                      child: Text('Montserrat'),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // About section
              const Text(
                'About',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const ListTile(
                title: Text('IronSworn Journal'),
                subtitle: Text('Version 1.0.0'),
              ),
              ListTile(
                title: const Text('Source Code'),
                subtitle: const Text('View on GitHub'),
                onTap: () {
                  // Open GitHub repository
                },
              ),
              ListTile(
                title: const Text('IronSworn'),
                subtitle: const Text('Learn more about the IronSworn RPG'),
                onTap: () {
                  // Open IronSworn website
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
