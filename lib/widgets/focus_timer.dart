import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';

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

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final minutes = timerProvider.remainingTime ~/ 60;
        final seconds = timerProvider.remainingTime % 60;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이머 카드
            Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타이머 제목
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '집중 타이머',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        if (timerProvider.status == TimerStatus.running ||
                            timerProvider.status == TimerStatus.paused)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: timerProvider.status == TimerStatus.running
                                  ? colorScheme.primary.withOpacity(0.15)
                                  : colorScheme.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  timerProvider.status == TimerStatus.running
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  size: 16,
                                  color: timerProvider.status ==
                                          TimerStatus.running
                                      ? colorScheme.primary
                                      : colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timerProvider.status == TimerStatus.running
                                      ? '진행중'
                                      : '일시정지',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: timerProvider.status ==
                                            TimerStatus.running
                                        ? colorScheme.primary
                                        : colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 타이머 현재 상태 정보
                    if ((timerProvider.status == TimerStatus.running ||
                            timerProvider.status == TimerStatus.paused) &&
                        timerProvider.startTime != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              context,
                              '현재작업',
                              timerProvider.title,
                              Icons.assignment_outlined,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              context,
                              '설정 시간',
                              '${timerProvider.initialDuration ~/ 60}분',
                              Icons.schedule_outlined,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              context,
                              '시작 시간',
                              _formatTimeAmPm(timerProvider.startTime!),
                              Icons.access_time_outlined,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // 타이머 원형 표시기
                    Center(
                      child: ConstrainedBox(
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
                                  end: timerProvider.status ==
                                          TimerStatus.finished
                                      ? 1.0
                                      : timerProvider.progress,
                                ),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, value, _) {
                                  final timerColor = timerProvider.status ==
                                          TimerStatus.finished
                                      ? AppTheme.successColor
                                      : timerProvider.remainingTime <=
                                              300 // 5분(300초) 이하
                                          ? colorScheme.error
                                          : colorScheme.primary;

                                  return Stack(
                                    children: [
                                      // 배경 원
                                      SizedBox.expand(
                                        child: CircularProgressIndicator(
                                          value: 1.0,
                                          strokeWidth: 12,
                                          backgroundColor: colorScheme
                                              .surfaceContainerHighest
                                              .withOpacity(0.3),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            colorScheme.surfaceContainerHighest,
                                          ),
                                        ),
                                      ),
                                      // 진행도 원
                                      SizedBox.expand(
                                        child: CircularProgressIndicator(
                                          value: value,
                                          strokeWidth: 12,
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  timerColor),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              // 타이머 시간 표시
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                    style: textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 60,
                                      letterSpacing: -1,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  if (timerProvider.status ==
                                      TimerStatus.finished)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        '완료!',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 타이머 입력 필드
                    TextField(
                      decoration: InputDecoration(
                        hintText: '무엇에 집중하시나요?',
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          color: colorScheme.primary.withOpacity(0.7),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      controller: _titleController,
                      onSubmitted: (value) {
                        timerProvider.setTitle(value);
                      },
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                      textInputAction: TextInputAction.done,
                    ),

                    const SizedBox(height: 24),

                    // 타이머 컨트롤 버튼들
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildTimerButton(
                            context,
                            timerProvider.status == TimerStatus.running
                                ? '일시정지'
                                : '시작',
                            timerProvider.status == TimerStatus.running
                                ? timerProvider.pause
                                : () {
                                    timerProvider
                                        .setTitle(_titleController.text);
                                    timerProvider.start();
                                  },
                            timerProvider.status == TimerStatus.running
                                ? Icons.pause
                                : Icons.play_arrow,
                            timerProvider.status == TimerStatus.running
                                ? colorScheme.secondary
                                : colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimerButton(
                            context,
                            timerProvider.status == TimerStatus.running
                                ? '중지'
                                : '리셋',
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
                                            color: colorScheme.onSurface,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
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
                                        content:
                                            const Text('타이머가 30분으로 초기화되었습니다.'),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                            timerProvider.status == TimerStatus.running
                                ? Icons.stop
                                : Icons.refresh,
                            timerProvider.status == TimerStatus.running
                                ? colorScheme.error
                                : colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 타이머 시간 조절 버튼
                    _buildDurationSelector(context, timerProvider),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 타이머 기록 리스트
            if (timerProvider.records.isNotEmpty)
              Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.history_outlined,
                              color: colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '타이머 기록',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: timerProvider.records.length,
                        itemBuilder: (context, index) {
                          final record = timerProvider.records[index];
                          final startTime = _formatTimeAmPm(record.startTime);
                          final duration = record.initialDuration ~/ 60;
                          final progressMinutes =
                              (record.initialDuration * record.progressRate)
                                      .round() ~/
                                  60;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: record.isCompleted
                                    ? colorScheme.primary.withOpacity(0.2)
                                    : colorScheme.error.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              record.title,
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: record.isCompleted
                                                  ? AppTheme.successColor
                                                      .withOpacity(0.2)
                                                  : colorScheme.error
                                                      .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              record.isCompleted ? '완료' : '중단',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: record.isCompleted
                                                    ? AppTheme.successColor
                                                    : colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildRecordInfoItem(
                                            context,
                                            Icons.access_time_outlined,
                                            startTime,
                                          ),
                                          const SizedBox(width: 16),
                                          _buildRecordInfoItem(
                                            context,
                                            Icons.timelapse_outlined,
                                            '${progressMinutes}분/${duration}분',
                                          ),
                                          const SizedBox(width: 16),
                                          _buildRecordInfoItem(
                                            context,
                                            Icons.percent_outlined,
                                            '${(record.progressRate * 100).round()}%',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // 진행 상태 바
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  child: LinearProgressIndicator(
                                    value: record.progressRate,
                                    backgroundColor: colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      record.isCompleted
                                          ? AppTheme.successColor
                                          : colorScheme.error,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordInfoItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildTimerButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
    IconData icon,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
      ),
    );
  }

  Widget _buildDurationSelector(
      BuildContext context, TimerProvider timerProvider) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTimeAdjustButton(context, timerProvider, -5, '- 5분',
            Theme.of(context).colorScheme.error),
        _buildTimeAdjustButton(context, timerProvider, 5, '+ 5분',
            Theme.of(context).colorScheme.secondary),
        _buildTimeAdjustButton(context, timerProvider, 15, '+ 15분',
            Theme.of(context).colorScheme.primary),
      ],
    );
  }

  Widget _buildTimeAdjustButton(
    BuildContext context,
    TimerProvider timerProvider,
    int minutes,
    String label,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: () {
        timerProvider.adjustDuration(minutes);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }

  // 현재 진행중인 타이머의 시작 시간을 위한 포맷 함수
  String _formatTimeAmPm(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? '오후' : '오전';
    return '$ampm ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
