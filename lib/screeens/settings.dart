import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kaluu_Epreess_Cargo/providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Appearance'),
          _buildAppearanceSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),
          _buildNotificationSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Language'),
          _buildLanguageSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Security'),
          _buildSecuritySection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Column(
            children: [
              _buildRadioOption(
                'System Default',
                ThemeMode.system,
                themeProvider.themeMode,
                (value) => themeProvider.setThemeMode(value!),
              ),
              const Divider(height: 1),
              _buildRadioOption(
                'Light Mode',
                ThemeMode.light,
                themeProvider.themeMode,
                (value) => themeProvider.setThemeMode(value!),
              ),
              const Divider(height: 1),
              _buildRadioOption(
                'Dark Mode',
                ThemeMode.dark,
                themeProvider.themeMode,
                (value) => themeProvider.setThemeMode(value!),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadioOption(
    String title,
    ThemeMode value,
    ThemeMode groupValue,
    ValueChanged<ThemeMode?> onChanged,
  ) {
    return RadioListTile<ThemeMode>(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive updates about your shipments'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Email Notifications'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement Email Notification settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        title: const Text('App Language'),
        subtitle: const Text('English'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Implement Language selection
        },
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement Change Password
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Biometric Login'),
            value: _biometricsEnabled,
            onChanged: (value) {
              setState(() {
                _biometricsEnabled = value;
              });
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
