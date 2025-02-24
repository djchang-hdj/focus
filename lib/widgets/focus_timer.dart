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
            Text(
              timerProvider.status == TimerStatus.running
                  ? timerProvider.title
                  : '집중타이머',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: '무엇에 집중하시나요?',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                          text: timerProvider.title == '무제'
                              ? ''
                              : timerProvider.title),
                      onSubmitted: (value) {
                        if (timerProvider.status == TimerStatus.running) {
                          timerProvider.setTitle(value);
                        }
                      },
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ),
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
                  timerProvider.status == TimerStatus.running ? '중지' : '리셋',
                  timerProvider.status == TimerStatus.running
                      ? () {
                          timerProvider.reset();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '타이머가 중지되었습니다.',
                                style: TextStyle(
                                  color: Colors.grey[100],
                                ),
                              ),
                              backgroundColor: Colors.black54,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : () {
                          timerProvider.reset();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '타이머가 30분으로 초기화되었습니다.',
                                style: TextStyle(
                                  color: Colors.grey[100],
                                ),
                              ),
                              backgroundColor: Colors.black54,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  timerProvider.status == TimerStatus.running
                      ? Icons.stop
                      : Icons.refresh,
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
        _buildTimeAdjustButton(context, timerProvider, -5, '- 5분'),
        const SizedBox(width: 8),
        _buildTimeAdjustButton(context, timerProvider, 5, '+ 5분'),
        const SizedBox(width: 8),
        _buildTimeAdjustButton(context, timerProvider, 15, '+ 15분'),
      ],
    );
  }

  Widget _buildTimeAdjustButton(
    BuildContext context,
    TimerProvider timerProvider,
    int minutes,
    String label,
  ) {
    return ElevatedButton(
      onPressed: () {
        timerProvider.adjustDuration(minutes);
      },
      child: Text(label),
    );
  }
}
