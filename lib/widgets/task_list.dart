import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 날짜 형식을 위해 추가
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../providers/timer_provider.dart';
import 'dart:ui' show lerpDouble;

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

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // tasks를 완료 여부에 따라 정렬
        final tasks = List<Task>.from(taskProvider.currentTasks)
          ..sort((a, b) {
            // 먼저 완료 여부로 정렬 (완료된 항목이 위로)
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? -1 : 1;
            }
            // 완료 여부가 같다면 기존 순서 유지
            return 0;
          });

        return Column(
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
                  buildDefaultDragHandles: false,
                  itemCount: tasks.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final movedTask = tasks[oldIndex];
                    final targetTask = tasks[newIndex];

                    // 같은 완료 상태 그룹 내에서만 이동 허용
                    if (movedTask.isCompleted == targetTask.isCompleted) {
                      taskProvider.reorderTask(oldIndex, newIndex);
                    } else {
                      // 다른 그룹으로 이동 시도하면 원래 위치로 돌아가도록 setState
                      setState(() {});
                    }
                  },
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ReorderableDragStartListener(
                      key: ValueKey(task.id),
                      index: index,
                      child: _buildTaskItem(context, task, taskProvider),
                    );
                  },
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final double elevation =
                            lerpDouble(1, 6, animation.value) ?? 0;
                        return Material(
                          elevation: elevation,
                          color: Colors.transparent,
                          shadowColor: Theme.of(context).shadowColor.withValues(
                                alpha: (Theme.of(context).shadowColor.a * 0.2)
                                    .toDouble(),
                                red: Theme.of(context).shadowColor.r.toDouble(),
                                green:
                                    Theme.of(context).shadowColor.g.toDouble(),
                                blue:
                                    Theme.of(context).shadowColor.b.toDouble(),
                              ),
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                ),
              ),
            _buildAddTaskField(context, taskProvider),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, TaskProvider taskProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: (Theme.of(context).colorScheme.primary.a * 0.1)
                      .toDouble(),
                  red: Theme.of(context).colorScheme.primary.r.toDouble(),
                  green: Theme.of(context).colorScheme.primary.g.toDouble(),
                  blue: Theme.of(context).colorScheme.primary.b.toDouble(),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            '할 일이 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: (Theme.of(context).colorScheme.primary.a * 0.1)
                            .toDouble(),
                        red: Theme.of(context).colorScheme.primary.r.toDouble(),
                        green:
                            Theme.of(context).colorScheme.primary.g.toDouble(),
                        blue:
                            Theme.of(context).colorScheme.primary.b.toDouble(),
                      ),
                ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _addDefaultTasks(taskProvider);
            },
            child: const Text('기본 할 일 추가하기'),
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
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final newDate =
                  taskProvider.selectedDate.subtract(const Duration(days: 1));
              taskProvider.selectDate(newDate);
            },
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
                  Text(
                    dateFormat.format(taskProvider.selectedDate),
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (!isToday)
                    TextButton(
                      onPressed: () {
                        taskProvider.selectDate(DateTime.now());
                      },
                      child: const Text('오늘로 이동'),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final newDate =
                  taskProvider.selectedDate.add(const Duration(days: 1));
              taskProvider.selectDate(newDate);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(TaskProvider taskProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('성취율'),
              Text(
                '${(taskProvider.completionRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: taskProvider.completionRate,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                    .withLightness(0.6)
                    .toColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
      BuildContext context, Task task, TaskProvider taskProvider) {
    return Card(
      key: ValueKey(task.id),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.8,
        ),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (bool? value) {
            taskProvider.toggleTask(task.id);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(76),
          ),
        ),
        title: GestureDetector(
          onDoubleTap: () {
            setState(() {
              task.isEditing = true;
            });
          },
          child: task.isEditing
              ? TextField(
                  controller: TextEditingController(text: task.title),
                  autofocus: true,
                  onSubmitted: (newValue) async {
                    if (newValue.isNotEmpty) {
                      await taskProvider.updateTask(task.id, newValue);
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
                )
              : Text(
                  task.title,
                  style: TextStyle(
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(
                              alpha: 128.0,
                              red: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.r
                                      .toDouble() ??
                                  0.0,
                              green: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.g
                                      .toDouble() ??
                                  0.0,
                              blue: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.b
                                      .toDouble() ??
                                  0.0,
                            )
                        : null,
                  ),
                ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!task.isCompleted)
              IconButton(
                icon: const Icon(Icons.timer),
                onPressed: () {
                  startTimer(task.title);
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                context.read<TaskProvider>().removeTask(task.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void startTimer(String taskTitle) {
    final timerProvider = context.read<TimerProvider>();
    if (timerProvider.status == TimerStatus.finished) {
      timerProvider.reset();
    }
    timerProvider.setTitle(taskTitle);
    timerProvider.start();
    widget.onTimerStart();
  }

  Widget _buildAddTaskField(BuildContext context, TaskProvider taskProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: '새로운 할 일 추가',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addTask(context, taskProvider, value);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 18,
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              _focusNode.requestFocus();
            },
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
