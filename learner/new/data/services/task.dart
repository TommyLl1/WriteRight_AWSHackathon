import 'dart:async';
import 'package:writeright/new/data/api_service.dart';
import 'package:writeright/new/data/models/task.dart';
import 'package:writeright/new/utils/logger.dart';

class TaskRepository {
  final ApiService apiService;
  List<Task> tasks = [];
  final StreamController<void> _taskUpdateController =
      StreamController.broadcast();
  Stream<void> get onTaskUpdate => _taskUpdateController.stream;

  TaskRepository(this.apiService);

  Future<List<Task>> fetchTasks() async {
    final response = await apiService.getCurrentTasks();
    final List<dynamic> data = response.data;
    tasks = data.map((e) => Task.fromJson(e)).toList();
    return tasks;
  }

  Future<List<Task>> getTasks() async {
    if (tasks.isNotEmpty) return tasks; // Check if tasks are already cached

    return await fetchTasks();
  }

  Future<void> incrementTaskProgress(String taskId, {int increment = 1}) async {
    AppLogger.debug(
        'TaskRepository: incrementTaskProgress fired, taskId: $taskId');
    // Use cached tasks if available, otherwise fetch
    if (tasks.isEmpty) {
      await fetchTasks();
    }
    final task = tasks.firstWhere((t) => t.taskId == taskId,
        orElse: () => throw Exception('Task not found'));
    final newProgress = (task.progress ?? 0) + increment;
    await apiService.setTaskProgress(taskId: taskId, progress: newProgress);
    // Refresh cache after update
    // delay a bit to ensure the API reflects the change
    await Future.delayed(const Duration(seconds: 1));
    await fetchTasks();
    _taskUpdateController.add(null); // Dispatch event
    AppLogger.debug('TaskRepository: _taskUpdateController event dispatched');
    AppLogger.debug(
        'TaskRepository: Stream has ${_taskUpdateController.hasListener ? "listeners" : "no listeners"}');
  }

  Future<void> incrementDailyAdventureTaskProgress() async {
    // Use cached tasks if available, otherwise fetch
    if (tasks.isEmpty) {
      await fetchTasks();
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    List<Task> dailyTasks = tasks
        .where((task) =>
            task.taskClass == 'daily' &&
            task.type == 'daily_adventure' &&
            (task.until == null || task.until! > now))
        .toList();
    // If no valid daily task, try to refresh from API once
    if (dailyTasks.isEmpty) {
      await fetchTasks();
      dailyTasks = tasks
          .where((task) =>
              task.taskClass == 'daily' &&
              task.type == 'daily_adventure' &&
              (task.until == null || task.until! > now))
          .toList();
    }
    if (dailyTasks.isNotEmpty) {
      final task = dailyTasks.first;
      await incrementTaskProgress(task.taskId);
    }
  }

  void dispose() {
    _taskUpdateController.close();
  }
}
