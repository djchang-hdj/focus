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
  final Map<String, FocusNode> _editFocusNodes = {};
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    for (final focusNode in _editFocusNodes.values) {
      focusNode.dispose();
    }
    for (final controller in _editControllers.values) {
      controller.dispose();
    }
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

        return GestureDetector(
          onTap: () {
            // 외부를 탭할 때 편집 중인 모든 작업 저장 및 편집 모드 종료
            taskProvider.saveAndCloseAllTaskEditors(_editControllers).then((_) {
              if (!mounted) return;
              setState(
                  () {}); // Ensure UI updates after async operation completes
            });
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
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
                      // 재정렬 전에 편집 중인 모든 작업 저장 및 편집 모드 종료
                      taskProvider
                          .saveAndCloseAllTaskEditors(_editControllers)
                          .then((_) {
                        if (!mounted) return;

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
                      });
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
                            shadowColor: Theme.of(context)
                                .shadowColor
                                .withValues(
                                  alpha: (Theme.of(context).shadowColor.a * 0.2)
                                      .toDouble(),
                                  red: Theme.of(context)
                                      .shadowColor
                                      .r
                                      .toDouble(),
                                  green: Theme.of(context)
                                      .shadowColor
                                      .g
                                      .toDouble(),
                                  blue: Theme.of(context)
                                      .shadowColor
                                      .b
                                      .toDouble(),
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
          ),
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
              // Save any ongoing edits before changing the date
              taskProvider
                  .saveAndCloseAllTaskEditors(_editControllers)
                  .then((_) {
                if (!mounted) return;
                final newDate =
                    taskProvider.selectedDate.subtract(const Duration(days: 1));
                taskProvider.selectDate(newDate);
              });
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _handleDatePickerTap(taskProvider),
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
                        // Save any ongoing edits before changing to today
                        taskProvider
                            .saveAndCloseAllTaskEditors(_editControllers)
                            .then((_) {
                          if (!mounted) return;
                          taskProvider.selectDate(DateTime.now());
                        });
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
              // Save any ongoing edits before changing the date
              taskProvider
                  .saveAndCloseAllTaskEditors(_editControllers)
                  .then((_) {
                if (!mounted) return;
                final newDate =
                    taskProvider.selectedDate.add(const Duration(days: 1));
                taskProvider.selectDate(newDate);
              });
            },
          ),
        ],
      ),
    );
  }

  // 날짜 선택기 탭 처리를 위한 메서드
  Future<void> _handleDatePickerTap(TaskProvider taskProvider) async {
    // 비동기 작업 전에 필요한 값 캡처
    final initialDate = taskProvider.selectedDate;

    // Save any ongoing edits before showing date picker
    await taskProvider.saveAndCloseAllTaskEditors(_editControllers);

    // mounted 체크
    if (!mounted) return;

    // 날짜 선택기 표시
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );

    // mounted 체크 후 날짜 업데이트
    if (date != null && mounted) {
      taskProvider.selectDate(date);
    }
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
    // 포커스 노드가 없으면 생성
    if (!_editFocusNodes.containsKey(task.id)) {
      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (!focusNode.hasFocus && task.isEditing) {
          // 포커스가 사라질 때 텍스트를 즉시 저장하고 편집 상태를 종료
          final controller = _editControllers[task.id];
          if (controller != null) {
            // 비동기 작업을 시작하기 전에 현재 텍스트 값을 캡처
            final currentText = controller.text;

            // UI 상태를 먼저 업데이트하여 사용자 경험 개선
            setState(() {
              // 편집 상태를 즉시 종료하여 UI 반응성 유지
              taskProvider.setTaskEditing(task.id, false);
            });

            // 그 후 비동기적으로 저장 작업 수행
            // 저장 실패 시 스낵바를 표시하는 로직을 별도 메서드로 분리
            _saveTaskAndShowErrorIfNeeded(task.id, currentText);
          }
        }
      });
      _editFocusNodes[task.id] = focusNode;
    }

    // 컨트롤러 관리 개선
    if (!_editControllers.containsKey(task.id)) {
      _editControllers[task.id] = TextEditingController(text: task.title);
    } else if (!task.isEditing) {
      // 편집 중이 아닐 때만 컨트롤러 텍스트 업데이트
      _editControllers[task.id]!.text = task.title;
    }

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
            // 다른 열린 에디터 먼저 닫기
            for (final otherTask in taskProvider.currentTasks) {
              if (otherTask.isEditing && otherTask.id != task.id) {
                final controller = _editControllers[otherTask.id];
                if (controller != null) {
                  // 비동기 작업을 시작하기 전에 현재 텍스트 값을 캡처
                  final currentText = controller.text;

                  // UI 상태를 먼저 업데이트
                  taskProvider.setTaskEditing(otherTask.id, false);

                  // 그 후 비동기적으로 저장
                  taskProvider.updateTask(otherTask.id, currentText);
                }
              }
            }

            // 이제 이 에디터 열기
            setState(() {
              taskProvider.setTaskEditing(task.id, true);
              // 다음 프레임에서 포커스 요청하여 키보드가 나타나도록 함
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _editFocusNodes[task.id]?.requestFocus();
                }
              });
            });
          },
          child: task.isEditing
              ? TextField(
                  controller: _editControllers[task.id],
                  focusNode: _editFocusNodes[task.id],
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (newValue) {
                    // 비동기 작업을 시작하기 전에 UI 상태 업데이트
                    setState(() {
                      taskProvider.setTaskEditing(task.id, false);
                    });

                    // 그 후 비동기적으로 저장
                    taskProvider.updateTask(task.id, newValue);
                  },
                  onEditingComplete: () {
                    final controller = _editControllers[task.id];
                    if (controller != null) {
                      // 비동기 작업을 시작하기 전에 UI 상태 업데이트
                      setState(() {
                        taskProvider.setTaskEditing(task.id, false);
                      });

                      // 그 후 비동기적으로 저장
                      taskProvider.updateTask(task.id, controller.text);
                    }
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
              onPressed: () async {
                // 작업이 제거될 때 포커스 노드와 컨트롤러 정리
                final focusNode = _editFocusNodes.remove(task.id);
                final controller = _editControllers.remove(task.id);

                // 작업이 편집 중이면 삭제 전에 내용 저장
                if (task.isEditing && controller != null) {
                  // 비동기 작업을 시작하기 전에 현재 텍스트 값을 캡처
                  final currentText = controller.text;

                  // UI 상태를 먼저 업데이트
                  setState(() {
                    taskProvider.setTaskEditing(task.id, false);
                  });

                  // 그 후 비동기적으로 저장 후 삭제
                  await taskProvider.updateTask(task.id, currentText);

                  // mounted 체크 추가
                  if (!mounted) {
                    focusNode?.dispose();
                    controller.dispose();
                    return;
                  }
                }

                // 그런 다음 작업 제거
                await taskProvider.removeTask(task.id);

                // mounted 체크 추가
                if (!mounted) {
                  focusNode?.dispose();
                  controller?.dispose();
                  return;
                }

                focusNode?.dispose();
                controller?.dispose();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 작업 저장 및 오류 표시를 위한 별도 메서드
  Future<void> _saveTaskAndShowErrorIfNeeded(String taskId, String text) async {
    // 비동기 작업 전에 BuildContext 캡처
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final success = await taskProvider.updateTask(taskId, text);

    // mounted 체크를 통해 위젯이 여전히 화면에 있는지 확인
    if (!success && mounted) {
      // 저장 실패 시 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('작업을 저장하는 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void startTimer(String taskTitle) {
    final timerProvider = context.read<TimerProvider>();

    // 이미 타이머가 실행 중인지 확인
    if (timerProvider.status == TimerStatus.running) {
      // 스낵바로 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.timer, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('이미 타이머가 실행 중입니다'),
                    Text(
                      '현재 작업: ${timerProvider.title}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '타이머로 이동',
            onPressed: widget.onTimerStart,
          ),
        ),
      );
      return;
    }

    if (timerProvider.status == TimerStatus.finished) {
      timerProvider.reset();
    }
    timerProvider.setTitle(taskTitle);
    timerProvider.start();
    widget.onTimerStart();
  }

  Widget _buildAddTaskField(BuildContext context, TaskProvider taskProvider) {
    return Container(
      padding: const EdgeInsets.all(8.0),
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
      // 비동기 작업 전에 값 캡처
      final textToAdd = value;
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // 텍스트 필드 즉시 초기화
      _textController.clear();

      final success = await taskProvider.addTask(textToAdd);

      // mounted 체크 추가
      if (!success && mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('작업을 저장하는 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
