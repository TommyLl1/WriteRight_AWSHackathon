import 'package:flutter/material.dart';

class ScanReminderDialog extends StatelessWidget {
  final bool allowProceed;
  final VoidCallback? onProceed;

  const ScanReminderDialog(
      {super.key, this.allowProceed = false, this.onProceed});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E4A5F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        allowProceed ? '尚未掃描錯別字' : '請先掃描錯別字',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Text(
        allowProceed
            ? '您目前還沒有任何錯別字紀錄，建議先使用「錯字偵探」功能掃描您的作業，才能獲得最佳體驗。\n\n確定要繼續進行冒險探索嗎？'
            : '您目前還沒有任何錯別字紀錄，請先使用「錯字偵探」功能掃描您的作業，才能進行冒險探索。',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: allowProceed
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  if (onProceed != null) onProceed!();
                },
                child:
                    const Text('仍要繼續', style: TextStyle(color: Colors.white)),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了', style: TextStyle(color: Colors.white)),
              ),
            ],
    );
  }
}
