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
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      if (timerProvider.title != '무제') {
        _titleController.text = timerProvider.title;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final minutes = timerProvider.remainingTime ~/ 60;
        final seconds = timerProvider.remainingTime % 60;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withAlpha(25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 현재 작업 정보
                if (timerProvider.status != TimerStatus.initial)
                  _buildCurrentWorkInfo(context, timerProvider),

                const SizedBox(height: 24),

                // 타이머 원형 프로그레스
                _buildTimerProgress(context, timerProvider, minutes, seconds),

                const SizedBox(height: 24),

                // 작업 제목 입력 필드와 컨트롤 버튼들
                _buildControls(context, timerProvider),

                const SizedBox(height: 24),

                // 시간 조절 버튼들
                _buildDurationAdjuster(context, timerProvider),

                // 타이머 기록
                if (timerProvider.records.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildTimerRecords(context, timerProvider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentWorkInfo(
      BuildContext context, TimerProvider timerProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            '현재작업:',
            timerProvider.title,
            Icons.work_outline,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            '설정 시간:',
            '${timerProvider.initialDuration ~/ 60}분',
            Icons.timer_outlined,
          ),
          if (timerProvider.startTime != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              '시작 시간:',
              _formatTimeAmPm(timerProvider.startTime!),
              Icons.access_time_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerProgress(
    BuildContext context,
    TimerProvider timerProvider,
    int minutes,
    int seconds,
  ) {
    final isFinished = timerProvider.status == TimerStatus.finished;
    final isNearEnd = timerProvider.remainingTime <= 300; // 5분 이하

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 300,
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 배경 원
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            // 진행 상태 애니메이션
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: isFinished ? 1.0 : timerProvider.progress,
              ),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) {
                return SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 24,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFinished
                            ? Theme.of(context).colorScheme.tertiary
                            : isNearEnd
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
            // 시간 표시
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 72,
                        letterSpacing: -1,
                      ),
                ),
                if (isFinished)
                  Text(
                    '완료!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, TimerProvider timerProvider) {
    return Row(
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
              focusNode: _titleFocusNode,
              onSubmitted: (value) {
                timerProvider.setTitle(value);
              },
              onTap: () {
                if (!_titleFocusNode.hasFocus) {
                  _titleFocusNode.requestFocus();
                }
              },
              onEditingComplete: () {
                timerProvider.setTitle(_titleController.text);
                _titleFocusNode.unfocus();
              },
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
                  timerProvider.pause();
                  final log = timerProvider.getTimerLog();
                  timerProvider.addRecord();
                  timerProvider.reset();
                  _titleController.clear();
                  _showSnackBar(context, log, isLog: true);
                }
              : () {
                  timerProvider.reset();
                  _titleController.clear();
                  _showSnackBar(context, '타이머가 30분으로 초기화되었습니다.');
                },
          timerProvider.status == TimerStatus.running
              ? Icons.stop
              : Icons.refresh,
        ),
      ],
    );
  }

  Widget _buildTimerButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
    IconData icon,
  ) {
    final isSystemButton = label == '중지' || label == '리셋';
    final isPlayPause = label == '시작' || label == '일시정지';

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: isPlayPause
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isPlayPause
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: isSystemButton
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: isSystemButton
              ? BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(25),
                )
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDurationAdjuster(
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
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(25),
          ),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTimerRecords(BuildContext context, TimerProvider timerProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                '타이머 기록',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${timerProvider.records.length}개',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: timerProvider.records.length,
          itemBuilder: (context, index) {
            final record = timerProvider.records[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withAlpha(25),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 제목 행 (타이틀과 상태, 삭제 버튼)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  record.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              _buildStatusBadge(context, record.isCompleted),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: _buildDeleteButton(
                                    context, timerProvider, index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 시간 정보 행
                          Row(
                            children: [
                              _buildRecordInfoChip(
                                context,
                                Icons.timer_outlined,
                                '${record.actualDuration ~/ 60}/${record.initialDuration ~/ 60}분',
                              ),
                              const SizedBox(width: 8),
                              _buildRecordInfoChip(
                                context,
                                Icons.schedule,
                                '${_formatTimeAmPm(record.startTime)} → ${_formatTimeAmPm(record.endTime)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildProgressBar(context, record),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecordInfoChip(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isCompleted
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha(40)
            : Theme.of(context).colorScheme.errorContainer.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCompleted
              ? Theme.of(context).colorScheme.primary.withAlpha(30)
              : Theme.of(context).colorScheme.error.withAlpha(30),
        ),
      ),
      child: Text(
        isCompleted ? '완료' : '중단',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    TimerProvider timerProvider,
    int index,
  ) {
    return IconButton(
      onPressed: () => timerProvider.deleteRecord(index),
      icon: const Icon(Icons.delete_outline),
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(4),
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, TimerRecord record) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(8),
        ),
      ),
      child: FractionallySizedBox(
        widthFactor: record.progressRate,
        child: Container(
          decoration: BoxDecoration(
            color: record.isCompleted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  // 현재 진행중인 타이머의 시작 시간을 위한 포맷 함수
  String _formatTimeAmPm(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? '오후' : '오전';
    return '$ampm ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  // SnackBar 스타일 개선
  void _showSnackBar(BuildContext context, String message,
      {bool isLog = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: isLog ? 'SF Mono' : '.SF Pro Text',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(25),
          ),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isLog ? 5 : 2),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
