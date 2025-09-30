import 'package:flutter/material.dart';

class DrawingPad extends StatefulWidget {
  final Function(List<Offset>)? onDrawingChanged;
  final bool isDisabled;

  const DrawingPad({super.key, this.onDrawingChanged, this.isDisabled = false});

  @override
  State<DrawingPad> createState() => _DrawingPadState();
}

class _DrawingPadState extends State<DrawingPad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onDrawingChanged?.call([]);
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
      widget.onDrawingChanged?.call(_strokes.expand((s) => s).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🎨 Drawing area expands to fill available space
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white, // White drawing board
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 6), // Black border
            ),
            child: GestureDetector(
              onPanStart: widget.isDisabled
                  ? null
                  : (details) {
                      setState(() {
                        _currentStroke = [details.localPosition];
                        _strokes.add(_currentStroke);
                      });
                    },
              onPanUpdate: widget.isDisabled
                  ? null
                  : (details) {
                      setState(() {
                        _currentStroke.add(details.localPosition);
                      });
                    },
              onPanEnd: widget.isDisabled
                  ? null
                  : (_) {
                      widget.onDrawingChanged?.call(
                        _strokes.expand((s) => s).toList(),
                      );
                    },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomPaint(painter: _DrawingPainter(_strokes)),
              ),
            ),
          ),
        ),

        // Buttons
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: widget.isDisabled ? null : _undo,
                child: const Text('Undo'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: widget.isDisabled ? null : _clear,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors
          .black // Black drawing path
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
