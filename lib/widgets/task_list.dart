import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 날짜 형식을 위해 추가
import '../providers/task_provider.dart';
import '../models/task.dart';

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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '할 일이 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
      key: ValueKey(task.id), // UUID만으로 충분합니다
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
              taskProvider.toggleTask(task.id);
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted
                  ? Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.5)
                  : null,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              taskProvider.deleteTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('할 일이 삭제되었습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 날짜 키 생성 헬퍼 메서드 추가
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
                  taskProvider.addTask(value);
                  _textController.clear();
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
}
