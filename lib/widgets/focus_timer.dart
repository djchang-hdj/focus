import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';

// 무지개 타이머 페인터
class RainbowTimerPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;

  RainbowTimerPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 배경 호 그리기 (세시부터 아홉시까지)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // 호는 각도가 라디안 단위이며, 0은 우측(3시 방향)에서 시작
    // 3시는 0라디안, 9시는 -pi
    canvas.drawArc(
      rect,
      0, // 시작 각도 (3시 방향)
      -math.pi, // 스윕 각도 (시계 반대 방향으로 180도 = 9시 방향까지)
      false,
      backgroundPaint,
    );

    // 무지개 색상 정의 - 역순으로 변경 (보라색부터 시작)
    final List<Color> rainbowColors = [
      const Color(0xFFAA00FF), // 밝은 보라
      const Color(0xFF3D5AFE), // 밝은 남색
      const Color(0xFF00B0FF), // 밝은 파랑
      const Color(0xFF00E676), // 밝은 초록
      const Color(0xFFFFEA00), // 밝은 노랑
      const Color(0xFFFF9100), // 밝은 주황
      const Color(0xFFFF1744), // 밝은 빨강
    ];

    // 전체 호의 각도는 -pi (180도)
    final totalAngle = math.pi;

    // 진행도에 맞는 총 각도 계산 (1.0~0.0 -> 0~-pi)
    final completedAngle = -totalAngle * progress;

    // 현재 진행에 맞는 색상 인덱스 계산
    final progressPct = 1 - progress; // 1.0에서 0.0으로 감소하는 값을 반전
    final colorIndex = math.min(
        (progressPct * rainbowColors.length).floor(), rainbowColors.length - 1);

    // 단색 페인트 생성 - 현재 진행율에 해당하는 무지개 색상 사용
    final arcPaint = Paint()
      ..color = rainbowColors[colorIndex]
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // 타이머 진행상황 그리기 (오른쪽에서 왼쪽으로)
    if (progress > 0) {
      canvas.drawArc(
        rect,
        0, // 항상 3시 방향에서 시작
        completedAngle, // 시계 반대방향으로 진행도만큼 그림
        false,
        arcPaint,
      );
    }

    // 끝 캡을 위한 작은 점을 그림 (진행된 위치에)
    if (progress > 0) {
      // 현재 진행 위치 계산
      final endAngle = completedAngle;
      final endPointX = center.dx + radius * math.cos(endAngle);
      final endPointY = center.dy + radius * math.sin(endAngle);

      // 캡 바깥 원
      final endCapOuterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endPointX, endPointY), 7, endCapOuterPaint);

      // 캡 내부 원 - 현재 메인 호와 동일한 색상 사용
      final endCapInnerPaint = Paint()
        ..color = rainbowColors[colorIndex]
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endPointX, endPointY), 4, endCapInnerPaint);
    }

    // 무지개 그라데이션 바 추가 (타이머 아래에 위치)
    final barHeight = 18.0;
    final barY = center.dy + radius * 0.6;

    // 그라데이션 바의 범위
    final barRect =
        Rect.fromLTWH(center.dx - radius * 0.8, barY, radius * 1.6, barHeight);

    // 무지개 그라데이션 생성 - 막대는 원래대로 빨주노초파남보 순서
    final List<Color> barColors = [
      const Color(0xFFFF1744), // 밝은 빨강
      const Color(0xFFFF9100), // 밝은 주황
      const Color(0xFFFFEA00), // 밝은 노랑
      const Color(0xFF00E676), // 밝은 초록
      const Color(0xFF00B0FF), // 밝은 파랑
      const Color(0xFF3D5AFE), // 밝은 남색
      const Color(0xFFAA00FF), // 밝은 보라
    ];

    final rainbowGradientBar = LinearGradient(
      colors: barColors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    // 배경 그리기 (회색 바)
    final backgroundBarPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final backgroundRRect =
        RRect.fromRectAndRadius(barRect, const Radius.circular(9));
    canvas.drawRRect(backgroundRRect, backgroundBarPaint);

    // 무지개 그라데이션 막대 (원래대로 복원)
    if (progress > 0) {
      // 진행된 만큼 바를 그림
      final progressWidth = barRect.width * progress;
      final progressRect =
          Rect.fromLTWH(barRect.left, barRect.top, progressWidth, barHeight);

      // 무지개 그라데이션 페인트
      final rainbowBarPaint = Paint()
        ..shader = rainbowGradientBar.createShader(barRect)
        ..style = PaintingStyle.fill;

      // 양쪽 모서리 둥글게
      final progressRRect = RRect.fromRectAndCorners(
        progressRect,
        topLeft: const Radius.circular(9),
        bottomLeft: const Radius.circular(9),
        topRight: progressWidth >= barRect.width * 0.95
            ? const Radius.circular(9)
            : Radius.zero,
        bottomRight: progressWidth >= barRect.width * 0.95
            ? const Radius.circular(9)
            : Radius.zero,
      );

      canvas.drawRRect(progressRRect, rainbowBarPaint);
    }

    // 남은 시간 퍼센트 텍스트 표시
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3.0,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        barRect.center.dx - textPainter.width / 2,
        barRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(RainbowTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

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
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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

                                  return CustomPaint(
                                    size: Size.infinite,
                                    painter: RainbowTimerPainter(
                                      progress: value,
                                      primaryColor: timerColor,
                                      backgroundColor: colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.3),
                                    ),
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
            if (timerProvider.recordsByDate.isNotEmpty)
              Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      colorScheme.secondary.withOpacity(0.15),
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
                          TextButton.icon(
                            onPressed: () {
                              // 모든 기록 지우기 확인 다이얼로그
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('모든 기록 삭제'),
                                  content: const Text(
                                      '모든 타이머 기록을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        timerProvider.clearAllRecords();
                                        Navigator.pop(context);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: colorScheme.error,
                                      ),
                                      child: const Text('삭제'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.delete_outlined,
                              size: 16,
                              color: colorScheme.error,
                            ),
                            label: Text(
                              '전체 삭제',
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 날짜별 타이머 기록
                      _buildDateGroupedRecords(context, timerProvider),
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

  // 날짜별로 그룹화된 타이머 기록을 표시하는 위젯
  Widget _buildDateGroupedRecords(
    BuildContext context,
    TimerProvider timerProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 가장 최근 날짜가 먼저 오도록 정렬
    final sortedDates = timerProvider.recordsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedDates.map((dateKey) {
        final records = timerProvider.getRecordsForDate(dateKey);

        // 날짜 표시 형식: '2023년 5월 1일 (월)'
        final date = DateTime.parse(dateKey);
        final formattedDate = _formatDateWithDay(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          formattedDate,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${records.length}개의 기록',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // 특정 날짜 기록 삭제 버튼
                  IconButton(
                    onPressed: () {
                      // 해당 날짜의 기록 삭제 확인 다이얼로그
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('$formattedDate 기록 삭제'),
                          content: const Text(
                              '이 날짜의 모든 타이머 기록을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () {
                                timerProvider.clearRecordsForDate(dateKey);
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.error,
                              ),
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: colorScheme.error.withOpacity(0.7),
                    ),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    tooltip: '이 날짜의 기록 삭제',
                  ),
                ],
              ),
            ),

            // 해당 날짜의 타이머 기록들
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final startTime = _formatTimeAmPm(record.startTime);
                final duration = record.initialDuration ~/ 60;
                final progressMinutes =
                    (record.initialDuration * record.progressRate).round() ~/
                        60;

                return Dismissible(
                  key: Key(
                      '${dateKey}_${index}_${record.startTime.millisecondsSinceEpoch}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    color: colorScheme.error,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    timerProvider.deleteRecord(dateKey, index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${record.title} 기록이 삭제되었습니다.'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: record.isCompleted
                            ? const Color(0xFFFF9100).withOpacity(0.5)
                            : colorScheme.outlineVariant.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      record.title,
                                      style: textTheme.titleMedium?.copyWith(
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
                                          : colorScheme.error.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      record.isCompleted ? '완료' : '중단',
                                      style: textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: record.isCompleted
                                            ? AppTheme.successColor
                                            : colorScheme.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('기록 삭제'),
                                          content: Text(
                                              '${record.title} 기록을 삭제하시겠습니까?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                timerProvider.deleteRecord(
                                                    dateKey, index);
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        '${record.title} 기록이 삭제되었습니다.'),
                                                    duration: const Duration(
                                                        seconds: 2),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    colorScheme.error,
                                              ),
                                              child: const Text('삭제'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: colorScheme.error.withOpacity(0.7),
                                    ),
                                    style: IconButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    tooltip: '기록 삭제',
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
                                    '$progressMinutes분/$duration분',
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
                            backgroundColor: colorScheme.surfaceContainerHighest
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
                  ),
                );
              },
            ),

            // 날짜 그룹 사이의 구분선
            if (sortedDates.indexOf(dateKey) < sortedDates.length - 1)
              const Divider(height: 32),
          ],
        );
      }).toList(),
    );
  }

  // 날짜 형식 포맷팅: '2023년 5월 1일 (월)'
  String _formatDateWithDay(DateTime date) {
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dayOfWeek = dayNames[date.weekday - 1]; // weekday는 1(월)~7(일)

    return '${date.year}년 ${date.month}월 ${date.day}일 ($dayOfWeek)';
  }
}
