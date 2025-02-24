import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 날짜 형식을 위해 추가
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../providers/timer_provider.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

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
        final tasks = taskProvider.currentTasks;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateSelector(context, taskProvider),
            _buildProgressBar(taskProvider),
            if (tasks.isEmpty)
              _buildEmptyState(context, taskProvider)
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskItem(context, tasks[index], taskProvider);
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
    return Dismissible(
      key: ValueKey(task.id),
      background: Container(
        color: Colors.red.shade300,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        taskProvider.deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('할 일이 삭제되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (bool? value) {
              context.read<TaskProvider>().toggleTask(task.id);
            },
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
                                alpha:
                                    (Theme.of(context).colorScheme.primary.a *
                                            0.1)
                                        .toDouble(),
                                red: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .r
                                    .toDouble(),
                                green: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .g
                                    .toDouble(),
                                blue: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .b
                                    .toDouble(),
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
                    final timerProvider = context.read<TimerProvider>();
                    if (timerProvider.status == TimerStatus.running) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('이미 다른 작업이 진행 중입니다.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      timerProvider.setTitle(task.title);
                      timerProvider.start();
                    }
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
      ),
    );
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
          FloatingActionButton(
            onPressed: () {
              _focusNode.requestFocus();
            },
            mini: true,
            child: const Icon(Icons.add),
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
