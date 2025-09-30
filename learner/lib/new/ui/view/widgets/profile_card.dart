import 'package:flutter/material.dart';
import 'package:writeright/new/data/models/task.dart'; 

class _TaskCarousel extends StatefulWidget {
  final List<Task> tasks;
  const _TaskCarousel({required this.tasks});

  @override
  State<_TaskCarousel> createState() => _TaskCarouselState();
}

class _TaskCarouselState extends State<_TaskCarousel> {
  late final PageController _controller;
  int _currentPage = 0;
  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.tasks.length > 1) {
      Future.microtask(_autoScroll);
    }
  }

  void _autoScroll() async {
    while (mounted && widget.tasks.length > 1) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) break;
      setState(() {
        _currentPage = (_currentPage + 1) % widget.tasks.length;
      });
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          String progressText = '';
          if (task.progress != null) {
            if (task.target != null) {
              progressText = ' (${task.progress}/${task.target})';
            } else {
              progressText = ' (${task.progress})';
            }
          }
          return Row(
            children: [
              Icon(
                task.completed
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: task.completed ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title + progressText,
                  style: TextStyle(
                    color: task.completed ? Colors.green : Colors.black87,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final int level;
  final double xpProgress;
  final List<Task> tasks;
  final int now;

  const ProfileCard({
    super.key,
    required this.level,
    required this.xpProgress,
    required this.tasks,
    required this.now,
  });

  Widget _buildTaskRow(List<Task> tasks, int now) {
    final validTasks = tasks
        .where((t) => t.until == null || (t.until != null && t.until! > now))
        .toList();
    if (validTasks.isEmpty) {
      return const Text('所有任務已完成🎉');
    }
    return _TaskCarousel(tasks: validTasks);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.8 * 255).toInt()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Lv. $level",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: xpProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 6),
            _buildTaskRow(tasks, now),
          ],
        ),
      ),
    );
  }
}
