import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view/widgets/scan_reminder_dialog.dart';
import 'package:writeright/new/ui/view_model/exports.dart';
import 'package:writeright/new/utils/logger.dart';


class NavigatorCard extends StatelessWidget {
  const NavigatorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue[900],
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomMenuItem(
              icon: Icons.search,
              label: '錯字偵探',
              onTap: () => _navigateToPage(context, "/get-photo"),
            ),
            _BottomMenuItem(
              icon: Icons.explore,
              label: '冒險探索',
              onTap: () => _navigateToPage(context, "/exercise"),
            ),
            _BottomMenuItem(
              icon: Icons.menu_book,
              label: '錯字庫',
              onTap: () => _navigateToPage(context, "/wrong-chars"),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(
      BuildContext context, String path) async {
    final viewModel = context.read<HomeViewModel>();
    if (path == "/exercise") {
      // Only intercept for ExercisePage
      try {
        final count = await viewModel.getUserWrongWordCount();
        if (count == 0) {
          // Use ScanReminderDialog with allowProceed
          if (context.mounted) {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => const ScanReminderDialog(allowProceed: true),
            );
            if (proceed != true) return;
          }
        }
      } catch (e) {
        // If error, allow navigation (or handle as needed)
      }
    }
    if (context.mounted) {
      // Use GoRouter to navigate
      context.go(path);
    } else {
      // If context is not mounted, log or handle as needed
      AppLogger.error("Context is not mounted, cannot navigate to $path");
    }
  }
}

class _BottomMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
