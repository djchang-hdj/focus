import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 날짜 형식을 위해 추가
import 'dart:ui' show lerpDouble; // lerpDouble 함수 임포트
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';

class TaskList extends StatefulWidget {
  final VoidCallback onTimerStart;

  const TaskList({
    super.key,
    required this.onTimerStart,
  });

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showLeftButton = false;
  bool _showRightButton = false;
  double _mouseY = 0;
  final Map<String, FocusNode> _taskFocusNodes = {};
  final Map<String, TextEditingController> _taskControllers = {};

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _taskFocusNodes.forEach((_, node) => node.dispose());
    _taskControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.currentTasks;

        return MouseRegion(
          onEnter: (_) => setState(() {
            _showLeftButton = false;
            _showRightButton = false;
          }),
          onExit: (_) => setState(() {
            _showLeftButton = false;
            _showRightButton = false;
          }),
          onHover: (event) {
            final size = MediaQuery.of(context).size;
            final cardWidth = size.width > 800 ? 800 : size.width;
            final leftEdgeZone = cardWidth * 0.05;
            final rightEdgeZone = cardWidth * 0.95;

            setState(() {
              _mouseY = event.localPosition.dy;
              _showLeftButton = event.localPosition.dx < leftEdgeZone;
              _showRightButton = event.localPosition.dx > rightEdgeZone;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDateSelector(context, taskProvider),
                  _buildProgressBar(taskProvider),
                  if (tasks.isEmpty)
                    _buildEmptyState(context, taskProvider)
                  else
                    Flexible(
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        onReorder: (oldIndex, newIndex) {
                          taskProvider.reorderTasks(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          return _buildTaskItem(
                            context,
                            tasks[index],
                            taskProvider,
                            key: ValueKey(tasks[index].id),
                          );
                        },
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (BuildContext context, Widget? child) {
                              final double animValue =
                                  Curves.easeInOut.transform(animation.value);
                              final double elevation =
                                  lerpDouble(0, 6, animValue)!;
                              return Material(
                                elevation: elevation,
                                color: Colors.transparent,
                                shadowColor: Theme.of(context)
                                    .colorScheme
                                    .shadow
                                    .withOpacity(0.3),
                                child: child,
                              );
                            },
                            child: child,
                          );
                        },
                        buildDefaultDragHandles: false,
                      ),
                    ),
                  _buildAddTaskField(context, taskProvider),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  double _getButtonYPosition() {
    // 화면 상단과 하단을 고려하여 버튼 위치 제한
    final minY = 50.0; // 최소 Y 위치 (상단 여백)
    final maxY = 500.0; // 최대 Y 위치 (하단 여백)

    // 버튼 높이의 절반을 빼서 마우스 커서 위치에 버튼 중앙이 오도록 함
    final buttonHalfHeight = 20.0;
    double y = _mouseY - buttonHalfHeight;

    // 화면 범위를 벗어나지 않도록 조정
    if (y < minY) y = minY;
    if (y > maxY) y = maxY;

    return y;
  }

  Widget _buildEmptyState(BuildContext context, TaskProvider taskProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.task_alt,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '할 일이 없습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 할 일을 추가하거나 기본 할 일을 불러와보세요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _addDefaultTasks(taskProvider);
            },
            icon: const Icon(Icons.add_task),
            label: const Text('기본 할 일 추가하기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addDefaultTasks(TaskProvider taskProvider) {
    final defaultTasks = [
      '이메일 플래그 지금 정리하라!',
      '과제 지금 관리하라!',
      '오늘 할 일 목록 당장 점검하라!',
      '책 30분 이상 읽어라!',
      '1시간 이상 집중 공부하라!',
      '오늘의 일기 반드시 작성하라!',
    ];

    for (final task in defaultTasks) {
      taskProvider.addTask(task);
    }
  }

  Widget _buildDateSelector(BuildContext context, TaskProvider taskProvider) {
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
    final today = DateTime.now();
    final selectedDate = taskProvider.selectedDate;
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final newDate =
                    taskProvider.selectedDate.subtract(const Duration(days: 1));
                taskProvider.selectDate(newDate);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.chevron_left,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: taskProvider.selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2025),
                );
                if (date != null) {
                  taskProvider.selectDate(date);
                }
              },
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(taskProvider.selectedDate),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (!isToday)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        onPressed: () {
                          taskProvider.selectDate(DateTime.now());
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '오늘로 이동',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final newDate =
                    taskProvider.selectedDate.add(const Duration(days: 1));
                taskProvider.selectDate(newDate);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(TaskProvider taskProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final completionRate = taskProvider.completionRate;
    final progressColor = HSLColor.fromColor(colorScheme.primary)
        .withLightness(HSLColor.fromColor(colorScheme.primary).lightness *
            (completionRate > 0.7 ? 0.8 : 0.6))
        .toColor();

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 성취율',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '${(completionRate * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: 0,
              end: completionRate,
            ),
            builder: (context, value, child) {
              return Stack(
                children: [
                  // 백그라운드 트랙
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // 진행상태 표시
                  Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * value * 0.8, // 컨테이너 크기에 맞게 조정
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: progressColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
      BuildContext context, Task task, TaskProvider taskProvider,
      {required Key key}) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_taskFocusNodes.containsKey(task.id)) {
      _taskFocusNodes[task.id] = FocusNode();
    }
    if (!_taskControllers.containsKey(task.id)) {
      _taskControllers[task.id] = TextEditingController(text: task.title);
    } else {
      _taskControllers[task.id]!.text = task.title;
    }

    final focusNode = _taskFocusNodes[task.id]!;
    final controller = _taskControllers[task.id]!;

    return MouseRegion(
      key: key,
      onEnter: (_) => setState(() {
        task.isHovered = true;
      }),
      onExit: (_) => setState(() {
        task.isHovered = false;
      }),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Dismissible(
            key: ValueKey(task.id),
            background: Container(
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              taskProvider.deleteTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('할 일이 삭제되었습니다'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: '실행 취소',
                    textColor: colorScheme.primary,
                    onPressed: () {
                      // 삭제된 작업 복원 (실제로는 구현되어야 함)
                    },
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? colorScheme.surfaceContainerLow.withOpacity(0.5)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(
                    task.isCompleted ? 0.1 : 0.3,
                  ),
                  width: 1,
                ),
                boxShadow: task.isCompleted
                    ? null
                    : [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        // 카드 싱글클릭 시 더 이상 체크 토글이 아님
                      });
                    },
                    onDoubleTap: () {
                      setState(() {
                        task.isEditing = true;
                        // 더블 클릭 시 다음 프레임에서 포커스 요청
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _taskFocusNodes[task.id]?.requestFocus();
                        });
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        task.isEditing = true;
                        // 길게 누를 때도 다음 프레임에서 포커스 요청
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _taskFocusNodes[task.id]?.requestFocus();
                        });
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          // 체크박스 부분
                          InkWell(
                            onTap: () {
                              context.read<TaskProvider>().toggleTask(task.id);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.fastOutSlowIn,
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: task.isCompleted
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: task.isCompleted
                                      ? colorScheme.primary
                                      : colorScheme.outline,
                                  width: 2,
                                ),
                              ),
                              child: task.isCompleted
                                  ? Center(
                                      child: Icon(
                                        Icons.check,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 제목 부분
                          Expanded(
                            child: task.isEditing
                                ? TextField(
                                    controller: controller,
                                    autofocus: true,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (newValue) async {
                                      if (newValue.isNotEmpty) {
                                        await taskProvider.updateTask(
                                            task.id, newValue);
                                        setState(() {
                                          task.isEditing = false;
                                        });
                                      }
                                    },
                                    onEditingComplete: () {
                                      setState(() {
                                        task.isEditing = false;
                                      });
                                    },
                                    onTapOutside: (event) async {
                                      if (controller.text.isNotEmpty) {
                                        await taskProvider.updateTask(
                                            task.id, controller.text);
                                      }
                                      setState(() {
                                        task.isEditing = false;
                                      });
                                    },
                                  )
                                : Text(
                                    task.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          decoration: task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: task.isCompleted
                                              ? colorScheme.onSurfaceVariant
                                                  .withOpacity(0.7)
                                              : colorScheme.onSurface,
                                          fontWeight: task.isCompleted
                                              ? FontWeight.normal
                                              : FontWeight.w500,
                                        ),
                                  ),
                          ),
                          if (!task.isCompleted)
                            IconButton(
                              icon: Icon(
                                Icons.timer_outlined,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                startTimer(task.title);
                              },
                              tooltip: '타이머 시작하기',
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.7),
                              size: 20,
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              context.read<TaskProvider>().removeTask(task.id);
                            },
                            tooltip: '삭제하기',
                          ),
                          // 드래그 핸들 - 휴지통 아이콘 오른쪽에 배치
                          ReorderableDragStartListener(
                            index: taskProvider.currentTasks.indexOf(task),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.grab,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: colorScheme.outline.withOpacity(0.7),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 왼쪽 화살표 (카드 바깥쪽)
          if (task.isHovered)
            Positioned(
              left: -15, // 카드 왼쪽 바깥으로 위치
              top: 0,
              bottom: 0,
              child: MouseRegion(
                onEnter: (_) => setState(() {
                  task.isHovered = true; // 마우스가 버튼 위에 있어도 호버 유지
                }),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final previousDay = taskProvider.selectedDate
                              .subtract(const Duration(days: 1));
                          final result = await taskProvider.moveTaskToDate(
                              task.id, previousDay);
                          if (result && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('할 일이 전날로 이동되었습니다'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 오른쪽 화살표 (카드 바깥쪽)
          if (task.isHovered)
            Positioned(
              right: -15, // 카드 오른쪽 바깥으로 위치
              top: 0,
              bottom: 0,
              child: MouseRegion(
                onEnter: (_) => setState(() {
                  task.isHovered = true; // 마우스가 버튼 위에 있어도 호버 유지
                }),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final nextDay = taskProvider.selectedDate
                              .add(const Duration(days: 1));
                          final result = await taskProvider.moveTaskToDate(
                              task.id, nextDay);
                          if (result && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('할 일이 다음날로 이동되었습니다'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void startTimer(String taskTitle) {
    final timerProvider = context.read<TimerProvider>();

    if (timerProvider.status == TimerStatus.running) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('타이머 전환'),
          content: const Text('현재 실행 중인 타이머가 있습니다. 어떻게 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final log = timerProvider.getTimerLog();
                timerProvider.reset();
                timerProvider.setTitle(taskTitle);
                timerProvider.start();
                widget.onTimerStart();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      log,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'monospace',
                      ),
                    ),
                    duration: const Duration(seconds: 5),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('기존 타이머 중단, 새로운 작업 시작'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        ),
      );
    } else {
      if (timerProvider.status == TimerStatus.finished) {
        timerProvider.reset();
      }
      timerProvider.setTitle(taskTitle);
      timerProvider.start();
      widget.onTimerStart();
    }
  }

  Widget _buildAddTaskField(BuildContext context, TaskProvider taskProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '새로운 할 일 추가',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.add_task,
                    color: colorScheme.primary.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _addTask(context, taskProvider, value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (_textController.text.isNotEmpty) {
                    _addTask(context, taskProvider, _textController.text);
                  } else {
                    _focusNode.requestFocus();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    Icons.send,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTask(
      BuildContext context, TaskProvider taskProvider, String value) async {
    if (value.isNotEmpty) {
      final success = await taskProvider.addTask(value);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('작업을 저장하는 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _textController.clear();
    }
  }
}
