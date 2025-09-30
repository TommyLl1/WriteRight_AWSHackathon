import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:writeright/new/data/services/image_cache.dart';
import 'package:writeright/new/data/services/wrong_character.dart';
import 'package:writeright/new/data/models/task.dart';
import 'package:writeright/new/data/models/user.dart';
import 'package:writeright/new/data/services/task.dart';
import 'package:writeright/new/data/services/user.dart';
import 'package:writeright/new/utils/logger.dart';

class HomeViewModel extends ChangeNotifier {
  final TaskRepository taskRepository;
  final UserRepository userRepository;
  final WrongCharacterService wrongCharacterService;
  final CommonImageCache imageCache;
  final SharedPreferences sharedPreferences;

  HomeViewModel({
    required this.taskRepository,
    required this.userRepository,
    required this.wrongCharacterService,
    required this.imageCache,
    required this.sharedPreferences,
  }) {
    AppLogger.debug(
        'HomeViewModel: Constructor called, setting up task update subscription');
    _taskUpdateSubscription = taskRepository.onTaskUpdate.listen((_) async {
      try {
        AppLogger.debug(
            'HomeViewModel: Task update event received, calling refresh()');
        await refresh();
      } catch (e, stackTrace) {
        AppLogger.error('HomeViewModel: Error in task update listener: $e');
        AppLogger.error('Stack trace: $stackTrace');
      }
    });
    _userUpdateSubscription = userRepository.onUserUpdate.listen((_) async {
      try {
        AppLogger.debug(
            'HomeViewModel: User update event received, calling refresh()');
        await refresh();
      } catch (e, stackTrace) {
        AppLogger.error('HomeViewModel: Error in user update listener: $e');
        AppLogger.error('Stack trace: $stackTrace');
      }
    });
    AppLogger.debug(
        'HomeViewModel: Task and user update subscriptions set up successfully');
  }

  late User _user;
  User get user => _user;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  /// progress bar progress for the current user
  double get xpProgress {
    final int nextLevelXp = xpForLevel(_user.level + 1);
    final int thisLevelXp = xpForLevel(_user.level);
    if (nextLevelXp == thisLevelXp) return 0.0;
    return (_user.exp - thisLevelXp) / (nextLevelXp - thisLevelXp);
  }

  int xpForLevel(num level) {
    return (10 * pow(level.toDouble(), 1.5)).ceil();
  }

  late Widget _backgroundImage;
  Widget get backgroundImage => _backgroundImage;

  late Widget _characterWidget;
  Widget get characterWidget => _characterWidget;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  StreamSubscription<void>? _taskUpdateSubscription;
  StreamSubscription<void>? _userUpdateSubscription;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return; // Prevent re-initialization
    _isLoading = true;
    notifyListeners();

    if (sharedPreferences.getString('userId') == null) {
      AppLogger.error('User ID not found! Please log in.');
      context.go('/login');
      return;
    }
    _tasks = await taskRepository.getTasks();
    _user = await userRepository.getUserStatus();

    _backgroundImage = imageCache.getBackgroundWidget();
    _characterWidget = imageCache.getCharacterWidget();

    // set initialized
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<int> getUserWrongWordCount() {
    return wrongCharacterService.getTotalCount();
  }

  Future<void> refresh({bool block = false}) async {
    AppLogger.debug('HomeViewModel: refresh() called');
    _isLoading = block ? true : _isLoading;
    notifyListeners();
    // Just use get here is fine
    // Whoever calls this method should fetch themselves
    // This should not issue any network requests
    _tasks = await taskRepository.getTasks();
    AppLogger.debug(
        'HomeViewModel: tasks refreshed, count: ${_tasks.length}${_tasks.isNotEmpty ? ", 0th progress: ${_tasks[0].progress}" : ""}');
    _user = await userRepository.getUserStatus();
    AppLogger.debug(
        'HomeViewModel: user refreshed, userId: ${_user.userId}, level: ${_user.level}, exp: ${_user.exp}');
    _isLoading = block ? false : _isLoading;
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.debug(
        'HomeViewModel: dispose() called, canceling task and user update subscriptions');
    _taskUpdateSubscription?.cancel();
    _userUpdateSubscription?.cancel();
    super.dispose();
  }

  // double _calcXpProgress(int level, int exp) {
  //   final int nextLevelXp = xpForLevel(level + 1);
  //   final int thisLevelXp = xpForLevel(level);
  //   return (exp - thisLevelXp) / (nextLevelXp - thisLevelXp);
  // }

  // int xpForLevel(num level) {
  //   return (10 * (level).pow(1.5).toDouble()).ceil();
  // }
}
