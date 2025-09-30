import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view_model/game.dart';

class SubmitButton extends StatefulWidget {
  final String text; // Button text
  final VoidCallback? onClick; // Callback for button press
  final double width; // Button width
  final double height; // Button height
  final Color activeColor; // Button color when active
  final Color inactiveColor; // Button color when inactive

  const SubmitButton({
    super.key,
    required this.text,
    this.onClick,
    this.width = double.infinity, // Default to full width
    this.height = 48, // Default height
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
  });

  @override
  _SubmitButtonState createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton>
    with SingleTickerProviderStateMixin {
  late bool isActive;
  late bool isLoading;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Animation duration
    );

    // Initialize color animation
    _colorAnimation = ColorTween(
      begin: widget.inactiveColor,
      end: widget.activeColor,
    ).animate(_animationController);

    // Fetch initial states from the ViewModel
    final viewModel = Provider.of<GameViewModel>(context, listen: false);
    isActive = viewModel.isSubmitButtonActive;
    isLoading = viewModel.isSubmitButtonLoading;

    // Sync initial animation state
    if (isActive) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen to changes in the ViewModel
    final viewModel = Provider.of<GameViewModel>(context);

    // If `isActive` changes, trigger the color animation
    if (isActive != viewModel.isSubmitButtonActive) {
      isActive = viewModel.isSubmitButtonActive;
      if (isActive) {
        _animationController.forward(); // Transition to active color
      } else {
        _animationController.reverse(); // Transition to inactive color
      }
    }

    // Update loading state
    if (isLoading != viewModel.isSubmitButtonLoading) {
      setState(() {
        isLoading = viewModel.isSubmitButtonLoading;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context);

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10), // Spacing around the button
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return ElevatedButton(
              onPressed: isActive && !isLoading
                  ? () {
                      if (widget.onClick != null) {
                        widget.onClick!(); // Trigger the provided callback
                      }
                    }
                  : null, // Disabled when inactive or loading
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorAnimation.value,
                foregroundColor: Colors.white,
                minimumSize: Size(widget.width, widget.height),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24), // Rounded corners
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.text,
                      style: const TextStyle(fontSize: 20),
                    ),
            );
          },
        ),
      ),
    );
  }
}