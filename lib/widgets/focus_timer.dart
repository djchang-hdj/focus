import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';

class FocusTimer extends StatefulWidget {
  const FocusTimer({super.key});

  @override
  State<FocusTimer> createState() => _FocusTimerState();
}

class _FocusTimerState extends State<FocusTimer> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // TextEditingController 초기값 설정
        if (_titleController.text.isEmpty && timerProvider.title != '무제') {
          _titleController.text = timerProvider.title;
        }

        final minutes = timerProvider.remainingTime ~/ 60;
        final seconds = timerProvider.remainingTime % 60;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((timerProvider.status == TimerStatus.running ||
                    timerProvider.status == TimerStatus.paused) &&
                timerProvider.startTime != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: '현재작업: ',
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: timerProvider.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          text: '설정 시간: ',
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: '${timerProvider.initialDuration ~/ 60}분',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          text: '시작 시간: ',
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: _formatTimeAmPm(timerProvider.startTime!),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 250,
                maxHeight: 250,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: timerProvider.status == TimerStatus.finished
                            ? 1.0
                            : timerProvider.progress,
                      ),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) {
                        return SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 24,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              timerProvider.status == TimerStatus.finished
                                  ? Colors.green
                                  : timerProvider.remainingTime <=
                                          300 // 5분(300초) 이하
                                      ? Theme.of(context)
                                          .colorScheme
                                          .error // 빨간색
                                      : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 70,
                              ),
                        ),
                        if (timerProvider.status == TimerStatus.finished)
                          Text(
                            '완료!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.green,
                                  fontSize: 32,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
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
                      controller: _titleController,
                      onSubmitted: (value) {
                        timerProvider.setTitle(value);
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
                      : () {
                          timerProvider.setTitle(_titleController.text);
                          timerProvider.start();
                        },
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
                          final log = timerProvider.getTimerLog();
                          timerProvider.reset();
                          _titleController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                log,
                                style: TextStyle(
                                  color: Colors.grey[100],
                                  fontFamily: 'monospace',
                                ),
                              ),
                              backgroundColor: Colors.black87,
                              duration: const Duration(seconds: 5),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : () {
                          timerProvider.reset();
                          _titleController.clear();
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

            const SizedBox(height: 20),
            // 타이머 기록 리스트
            if (timerProvider.records.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '타이머 기록',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: timerProvider.records.length,
                itemBuilder: (context, index) {
                  final record = timerProvider.records[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '제목: ${record.title}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    timerProvider.deleteRecord(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          Text('설정 시간: ${record.initialDuration ~/ 60}분'),
                          Text('총 진행 시간: ${record.actualDuration ~/ 60}분'),
                          Text('시작 시간: ${_formatDateTime(record.startTime)}'),
                          Text('종료 시간: ${_formatDateTime(record.endTime)}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
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

  // 현재 진행중인 타이머의 시작 시간을 위한 포맷 함수
  String _formatTimeAmPm(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? '오후' : '오전';
    return '$ampm ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // 기존의 포맷 함수는 기록을 위해 유지
  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
