import 'package:flutter/material.dart';
import 'package:writeright/new/data/models/questions.dart';

class MultiChoiceGrid extends StatefulWidget {
  final List<MultiChoiceOption> options;
  final Function(MultiChoiceOption) onSelectionChanged;
  final int rows;
  final int columns;

  const MultiChoiceGrid({
    super.key,
    required this.options,
    required this.onSelectionChanged,
    this.rows = 2,
    this.columns = 2,
  });

  @override
  _MultiChoiceGridState createState() => _MultiChoiceGridState();
}

class _MultiChoiceGridState extends State<MultiChoiceGrid> {
  MultiChoiceOption? selectedOption;

  @override
  Widget build(BuildContext context) {
    // Effective number of columns
    final int effectiveColumns = widget.options.length > 4 ? 2 : widget.columns;

    // Split options into rows
    final List<List<MultiChoiceOption>> rows = [];
    for (int i = 0; i < widget.options.length; i += effectiveColumns) {
      rows.add(widget.options.sublist(
        i,
        i + effectiveColumns > widget.options.length
            ? widget.options.length
            : i + effectiveColumns,
      ));
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20), // Left and right padding
      alignment: Alignment.center,
      constraints: const BoxConstraints(
        maxWidth: 600, // Set the maximum width
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: rows.map((row) {
          return Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((option) {
                final bool isSelected = selectedOption == option;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedOption = option;
                      });
                      widget.onSelectionChanged(option);
                    },
                    child: AspectRatio(
                      aspectRatio: 1, // Ensures a square button
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 200), // Animation duration
                        margin:
                            const EdgeInsets.all(5), // Spacing between boxes
                        decoration: BoxDecoration(
                          color:
                              (isSelected ? Colors.blueAccent : Colors.black87)
                                  .withAlpha(
                                      (0.5 * 255).toInt()), // 50% transparency
                          borderRadius:
                              BorderRadius.circular(16), // Rounded corners
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          option.text ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
