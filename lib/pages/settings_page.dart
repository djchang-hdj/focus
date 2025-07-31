import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus/providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timer Duration',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Slider(
                  value: settingsProvider.timerDuration.toDouble(),
                  min: 1,
                  max: 120,
                  divisions: 119,
                  label: '${settingsProvider.timerDuration} minutes',
                  onChanged: (value) {
                    settingsProvider.setTimerDuration(value.toInt());
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
