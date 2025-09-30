import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view_model/exports.dart';

class FlagQuestionDialog extends StatefulWidget {
  final String questionId;
  final GameViewModel viewModel;
  const FlagQuestionDialog(
      {super.key, required this.questionId, required this.viewModel});

  @override
  State<FlagQuestionDialog> createState() => _FlagQuestionDialogState();
}

class _FlagQuestionDialogState extends State<FlagQuestionDialog> {
  String? _selectedReason;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  static const Map<String, String> reasonLabels = {
    'wrong-layout': '題目排版錯誤',
    'multi-correct': '多個正確答案',
    'none-correct': '沒有正確答案',
    'wrong-solution': '標準答案錯誤',
    'unsafe': '不安全內容',
    'wrong-question': '問題編寫錯誤',
    'i-just-hate-it': '我就是討厭這題',
    'none-of-the-above': '其他',
  };

  Future<void> _submitFlag(BuildContext context) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    if (widget.viewModel.currentQuestion == null) {
      return;
    }
    try {
      final success = await widget.viewModel.flagQuestion(
        questionId: widget.questionId,
        reason: _selectedReason,
      );
      if (success) {
        setState(() {
          _submitted = true;
        });
      } else {
        setState(() {
          _error = '提交失敗，請稍後再試';
        });
      }
    } catch (e) {
      setState(() {
        _error = '提交失敗：$e';
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return AlertDialog(
        title: const Text('感謝您的回報'),
        content: const Text('我們已收到您的意見，會盡快處理。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: const Text('回報問題'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...reasonLabels.entries.map((entry) => RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _selectedReason,
                onChanged: _submitting
                    ? null
                    : (val) => setState(() => _selectedReason = val),
              )),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submitting || _selectedReason == null
              ? null
              : () => _submitFlag(context),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('提交'),
        ),
      ],
    );
  }
}

// Example usage:
// showDialog(
//   context: context,
//   builder: (context) => FlagQuestionDialog(questionId: questionId),
// );
