import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';

class FocusTimer extends StatelessWidget {
  const FocusTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final minutes = timerProvider.remainingTime ~/ 60;
        final seconds = timerProvider.remainingTime % 60;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: timerProvider.progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                          .withLightness(0.6)
                          .toColor(),
                    ),
                  ),
                ),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerButton(
                  context,
                  timerProvider.status == TimerStatus.running ? '일시정지' : '시작',
                  timerProvider.status == TimerStatus.running
                      ? timerProvider.pause
                      : timerProvider.start,
                  timerProvider.status == TimerStatus.running
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                const SizedBox(width: 20),
                _buildTimerButton(
                  context,
                  '리셋',
                  timerProvider.reset,
                  Icons.refresh,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDurationSelector(context, timerProvider),
          ],
        );
      },
    );
  }

  Widget _buildTimerButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
    IconData icon,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildDurationSelector(
      BuildContext context, TimerProvider timerProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimePresetButton(context, timerProvider, 15),
        const SizedBox(width: 8),
        _buildTimePresetButton(context, timerProvider, 25),
        const SizedBox(width: 8),
        _buildTimePresetButton(context, timerProvider, 45),
      ],
    );
  }

  Widget _buildTimePresetButton(
    BuildContext context,
    TimerProvider timerProvider,
    int minutes,
  ) {
    final isSelected = timerProvider.duration == minutes * 60;
    return FilterChip(
      label: Text('$minutes분'),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          timerProvider.setDuration(minutes);
        }
      },
    );
  }
}
