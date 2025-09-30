import 'package:flutter/material.dart';
import 'package:writeright/new/data/models/questions.dart';

class MultiChoiceList extends StatefulWidget {
  final List<MultiChoiceOption> options;
  final Function(MultiChoiceOption) onSelectionChanged;

  const MultiChoiceList({
    super.key,
    required this.options,
    required this.onSelectionChanged,
  });

  @override
  MultiChoiceListState createState() => MultiChoiceListState();
}

class MultiChoiceListState extends State<MultiChoiceList> {
  MultiChoiceOption? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30), // Left-right padding
      alignment: Alignment.center,
      constraints: const BoxConstraints(
        maxWidth: 600, // Maximum width constraint
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.options.map((option) {
          final bool isSelected = selectedOption == option;

          return Container(
            constraints: const BoxConstraints(
              minWidth: 100, // Smaller minimum width
              minHeight: 40, // Much smaller minimum height
            ),
            margin: const EdgeInsets.symmetric(
                vertical: 8), // Spacing between buttons
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedOption = option;
                });
                widget.onSelectionChanged(option);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300), // Smooth animation
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: (isSelected ? Colors.blueAccent : Colors.black87)
                      .withAlpha((0.5 * 255).toInt()), // 50% transparency
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown, // Shrinks text to prevent overflow
                  child: Text(
                    option.text ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize:
                          18, // Slightly smaller font size for compact buttons
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
