import 'package:flutter/material.dart';

enum SegmentState {
  pending,
  current,
  completed,
  failed, // For wrong answers if needed in the future
}

class SegmentedProgressBar extends StatelessWidget {
  final int totalSegments;
  final int currentSegment;
  final Color completedColor;
  final Color pendingColor;
  final Color currentColor;
  final Color failedColor;
  final double height;
  final double segmentSpacing;
  final List<SegmentState>?
  segmentStates; // Optional custom states for each segment

  const SegmentedProgressBar({
    super.key,
    required this.totalSegments,
    required this.currentSegment,
    this.completedColor = const Color(0xFF4CAF50), // Green for completed
    this.pendingColor = const Color(0xFF424242), // Dark gray for pending
    this.currentColor = const Color(0xFF2196F3), // Blue for current
    this.failedColor = const Color(0xFFF44336), // Red for failed
    this.height = 8.0,
    this.segmentSpacing = 4.0,
    this.segmentStates,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSegments, (index) {
        Color segmentColor;

        // Use custom segment states if provided, otherwise use default logic
        if (segmentStates != null && index < segmentStates!.length) {
          switch (segmentStates![index]) {
            case SegmentState.completed:
              segmentColor = completedColor;
              break;
            case SegmentState.current:
              segmentColor = currentColor;
              break;
            case SegmentState.failed:
              segmentColor = failedColor;
              break;
            case SegmentState.pending:
              segmentColor = pendingColor;
              break;
          }
        } else {
          // Default logic based on current segment
          if (index < currentSegment) {
            // Completed segments
            segmentColor = completedColor;
          } else if (index == currentSegment) {
            // Current segment
            segmentColor = currentColor;
          } else {
            // Pending segments
            segmentColor = pendingColor;
          }
        }

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < totalSegments - 1 ? segmentSpacing : 0,
            ),
            height: height,
            decoration: BoxDecoration(
              color: segmentColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      }),
    );
  }
}
